local M = {}
local api = vim.api

--------------------------------------------------------------------------------
-- 0. 状态管理 (State & Index)
--------------------------------------------------------------------------------

-- M.index[id] = { archived = boolean, alt_id = string|nil }
M.index = {}

local function parse_note_header(filepath)
  if vim.fn.filereadable(filepath) == 0 then
    return nil
  end
  -- 只读取前10行，提高性能
  local lines = vim.fn.readfile(filepath, "", 10)
  local info = { archived = false, alt_id = nil, id = nil }

  for _, line in ipairs(lines) do
    -- 提取ID: = Title <ID>
    local id = line:match("^=%s*.-%s*<(%d+)>")
    if id then
      info.id = id
    end

    -- 提取Archived状态
    if line:match("#tag%.archived") then
      info.archived = true
    end

    -- 提取Alternative Link
    local alt = line:match("#alternative_link%s*%(%s*<(%d+)>%s*%)")
    if alt then
      info.alt_id = alt
    end
  end

  return info.id and info or nil
end

local function refresh_index(root_dir)
  local notes = vim.fn.globpath(root_dir .. "/note", "*.typ", false, true)
  for _, filepath in ipairs(notes) do
    local info = parse_note_header(filepath)
    if info then
      M.index[info.id] = { archived = info.archived, alt_id = info.alt_id }
    end
  end
end

--------------------------------------------------------------------------------
-- 1. 业务逻辑 (Server Logic)
--------------------------------------------------------------------------------

local function get_all_notes(root_dir)
  return vim.fn.globpath(root_dir .. "/note", "*.typ", false, true)
end

-- 查找引用 (保持不变)
local function find_references(params, root_dir)
  local uri = params.textDocument.uri
  local row = params.position.line
  local bufnr = vim.uri_to_bufnr(uri)

  local lines = api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  if #lines == 0 then
    return {}
  end

  local id = lines[1]:match("<(%d+)>")
  if not id then
    id = vim.fn.expand("<cword>")
    if not id:match("^%d+$") then
      return {}
    end
  end

  local target_str = "@" .. id
  local locations = {}
  local note_files = get_all_notes(root_dir)

  for _, filepath in ipairs(note_files) do
    if vim.fn.filereadable(filepath) == 1 then
      local f_lines = vim.fn.readfile(filepath)
      for lnum, f_line in ipairs(f_lines) do
        local start_col, end_col = string.find(f_line, target_str, 1, true)
        if start_col then
          table.insert(locations, {
            uri = vim.uri_from_fname(filepath),
            range = {
              start = { line = lnum - 1, character = start_col - 1 },
              ["end"] = { line = lnum - 1, character = end_col },
            },
          })
        end
      end
    end
  end
  return locations
end

-- 生成诊断 (Check for archived references)
local function get_diagnostics(uri)
  local bufnr = vim.uri_to_bufnr(uri)
  if not api.nvim_buf_is_valid(bufnr) then
    return {}
  end

  local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local diagnostics = {}

  for lnum, line in ipairs(lines) do
    -- 查找行内所有 @ID 格式
    local cur_pos = 1
    while true do
      local start_col, end_col, ref_id = line:find("@(%d+)", cur_pos)
      if not start_col then
        break
      end

      local note_info = M.index[ref_id]
      if note_info and note_info.archived then
        local msg = "Note @" .. ref_id .. " is archived."
        if note_info.alt_id then
          msg = msg .. " New version: @" .. note_info.alt_id
        end

        table.insert(diagnostics, {
          range = {
            start = { line = lnum - 1, character = start_col - 1 },
            ["end"] = { line = lnum - 1, character = end_col },
          },
          severity = 2, -- Warning
          message = msg,
          source = "zk-lsp",
          -- 将新ID存入data，供CodeAction使用
          data = { old_id = ref_id, new_id = note_info.alt_id },
        })
      end
      cur_pos = end_col + 1
    end
  end
  return diagnostics
end

-- 代码行动 (Quick Fix)
local function get_code_actions(params)
  local diagnostics = params.context.diagnostics
  local actions = {}

  for _, diag in ipairs(diagnostics) do
    if diag.source == "zk-lsp" and diag.data and diag.data.new_id then
      local new_text = "@" .. diag.data.new_id
      table.insert(actions, {
        title = "Fix: Replace with " .. new_text,
        kind = "quickfix",
        edit = {
          changes = {
            [params.textDocument.uri] = {
              {
                range = diag.range,
                newText = new_text,
              },
            },
          },
        },
      })
    end
  end
  return actions
end

--------------------------------------------------------------------------------
-- 2. LSP 服务器定义 (Mock Server)
--------------------------------------------------------------------------------

local function create_server_cmd(root_dir)
  return function(dispatchers)
    local closing = false

    -- 辅助：推送诊断到客户端
    local function publish_diagnostics(uri)
      local diags = get_diagnostics(uri)
      dispatchers.notification("textDocument/publishDiagnostics", {
        uri = uri,
        diagnostics = diags,
      })
    end

    return {
      request = function(method, params, handler)
        if method == "initialize" then
          -- 初始化时构建全量索引
          refresh_index(root_dir)
          handler(nil, {
            capabilities = {
              referencesProvider = true,
              codeActionProvider = true, -- 支持 CodeAction
              textDocumentSync = 1,
            },
          })
        elseif method == "textDocument/references" then
          local status, result = pcall(find_references, params, root_dir)
          handler(status and nil or result, status and result or nil)
        elseif method == "textDocument/codeAction" then
          local status, result = pcall(get_code_actions, params)
          handler(status and nil or result, status and result or nil)
        elseif method == "shutdown" then
          handler(nil, nil)
        else
          handler(nil, nil)
        end
      end,

      notify = function(method, params)
        if method == "exit" then
          dispatchers.on_exit(0, 15)

        -- 打开/保存文件时触发诊断
        elseif method == "textDocument/didOpen" then
          publish_diagnostics(params.textDocument.uri)
        elseif method == "textDocument/didSave" then
          -- 如果保存的是笔记文件，更新该笔记的索引
          local filepath = vim.uri_to_fname(params.textDocument.uri)
          if filepath:match("/note/") then
            local info = parse_note_header(filepath)
            if info then
              M.index[info.id] = { archived = info.archived, alt_id = info.alt_id }
            end
          end
          -- 重新发布当前文件的诊断
          publish_diagnostics(params.textDocument.uri)
        end
      end,

      is_closing = function()
        return closing
      end,
      terminate = function()
        closing = true
      end,
    }
  end
end

--------------------------------------------------------------------------------
-- 3. 配置与启动 (Configuration)
--------------------------------------------------------------------------------

M.config = {
  name = "zk-lsp",
  filetypes = { "typst" },
  root_dir = vim.fn.expand("~/wiki"),
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Neovim 0.11+ 注册方式
  if vim.lsp.config then
    vim.lsp.config("zk-lsp", {
      name = opts.name,
      cmd = create_server_cmd(opts.root_dir),
      root_dir = opts.root_dir,
      filetypes = opts.filetypes,
    })
  else
    vim.notify("ZK-LSP requires Neovim 0.11+ (vim.lsp.config)", vim.log.levels.ERROR)
  end
end

return M
