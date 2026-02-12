local M = {}
local api = vim.api

--------------------------------------------------------------------------------
-- 1. 业务逻辑 (Server Logic)
--------------------------------------------------------------------------------

-- 辅助：获取笔记路径
local function get_all_notes(root_dir)
  return vim.fn.globpath(root_dir .. "/note", "*.typ", false, true)
end

-- 核心：查找引用
local function find_references(params, root_dir)
  local uri = params.textDocument.uri
  local row = params.position.line
  local bufnr = vim.uri_to_bufnr(uri)

  -- 读取当前行
  local lines = api.nvim_buf_get_lines(bufnr, row, row + 1, false)
  if #lines == 0 then
    return {}
  end

  -- 提取 ID：优先匹配 <ID>，其次匹配光标下单词
  local id = lines[1]:match("<(%d+)>")
  if not id then
    id = vim.fn.expand("<cword>")
    if not id:match("^%d+$") then
      return {}
    end
  end

  -- 搜索目标
  local target_str = "@" .. id
  local locations = {}
  local note_files = get_all_notes(root_dir)

  -- 扫描文件
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

--------------------------------------------------------------------------------
-- 2. LSP 服务器定义 (Mock Server)
--------------------------------------------------------------------------------

local function create_server_cmd(root_dir)
  return function(dispatchers)
    local closing = false
    return {
      request = function(method, params, handler)
        -- A. 握手阶段：声明能力
        if method == "initialize" then
          handler(nil, {
            capabilities = {
              referencesProvider = true, -- 告诉 Neovim 我们支持 Reference
              textDocumentSync = 1,
            },
          })

        -- B. 核心功能：Reference
        elseif method == "textDocument/references" then
          local status, result = pcall(find_references, params, root_dir)
          if status then
            handler(nil, result)
          else
            handler(result, nil)
          end

        -- C. 关闭
        elseif method == "shutdown" then
          handler(nil, nil)

        -- D. 其他请求：返回 nil (不支持)
        else
          handler(nil, nil)
        end
      end,
      notify = function(method, params)
        if method == "exit" then
          dispatchers.on_exit(0, 15)
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

-- 默认配置
M.config = {
  name = "zk-lsp",
  filetypes = { "typst" }, -- 这里定义支持的文件类型
  root_dir = vim.fn.expand("~/wiki"),
}

function M.setup(opts)
  -- 合并用户配置
  opts = vim.tbl_deep_extend("force", M.config, opts or {})

  -- 注册 LSP 服务器
  vim.lsp.config("zk-lsp", {
    name = opts.name,
    cmd = create_server_cmd(opts.root_dir),
    root_dir = opts.root_dir,
    filetypes = opts.filetypes,
  })
end

return M
