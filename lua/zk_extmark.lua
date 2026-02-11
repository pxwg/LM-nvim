local M = {}

local config = {
  note_root = vim.fn.expand("~/wiki/note"),
  extension = ".typ",
  cache = {},
  hl_group = "Identifier", -- 标题的颜色
}

-- 命名空间
local ns_id = vim.api.nvim_create_namespace("zk_typst_titles")

--- 从文件中读取标题
local function get_title_from_file(id)
  if config.cache[id] then
    return config.cache[id]
  end
  local filepath = string.format("%s/%s%s", config.note_root, id, config.extension)
  local file = io.open(filepath, "r")
  if not file then
    return nil
  end

  local title = nil
  for _ = 1, 5 do
    local line = file:read("*line")
    if not line then
      break
    end
    if line:match("^=%s+") then
      title = line:gsub("^=%s+", ""):gsub("%s*<.*>$", "")
      break
    end
  end
  file:close()
  if title then
    config.cache[id] = title
  end
  return title
end

--- 刷新当前 Buffer 的 Extmarks
function M.refresh_extmarks()
  local bufnr = vim.api.nvim_get_current_buf()
  local noteid = vim.api.nvim_buf_get_name(0):match("note/(%d+)%.typ$")

  if vim.bo[bufnr].filetype ~= "typst" and not noteid then
    return
  end

  -- 确保开启 conceallevel
  vim.opt_local.conceallevel = 2

  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for line_idx, line in ipairs(lines) do
    local current_pos = 1

    while true do
      -- 匹配 @ + 10位数字
      local s, e, id = string.find(line, "@(%d%d%d%d%d%d%d%d%d%d)", current_pos)

      if not s then
        break
      end

      local title = get_title_from_file(id)

      if title then
        -- Extmark 1: 负责隐藏 (Conceal)
        -- 将 @260... 整个区域隐藏，只显示一个 "@"
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx - 1, s - 1, {
          end_col = e,
          conceal = "@",
          hl_group = config.hl_group,
        })

        -- Extmark 2: 负责显示标题 (Virt Text)
        -- 位置设置在 'e' (即 ID 的末尾)，这样标题就会出现在 @ 的后面
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, line_idx - 1, e, {
          virt_text = { { title, config.hl_group } },
          virt_text_pos = "inline",
          hl_mode = "combine",
        })
      end

      current_pos = e + 1
    end
  end
end

--- 启动函数
function M.setup(opts)
  if opts then
    for k, v in pairs(opts) do
      config[k] = v
    end
  end

  local group = vim.api.nvim_create_augroup("ZkExtmarkRefresh", { clear = true })

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave", "TextChanged" }, {
    group = group,
    pattern = "*.typ",
    callback = function(ev)
      -- Fix: 切换 Buffer (BufEnter) 或 保存文件 (BufWritePost) 时清空缓存
      -- 这样能确保读取到其他文件最新的标题修改，同时保留 TextChanged 时的性能
      if ev.event == "BufEnter" or ev.event == "BufWritePost" then
        config.cache = {}
      end
      M.refresh_extmarks()
    end,
  })

  vim.schedule(M.refresh_extmarks)
end

return M
