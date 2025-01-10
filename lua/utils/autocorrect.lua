local M = {}

-- HACK: 用于对终端 autocorrect 的修正

function M.autocorrect()
  local path = vim.fn.expand("%:p")

  local cmd = "autocorrect " .. path
  local handle = io.popen(cmd)
  if handle == nil then
    vim.notify("Failed to execute autocorrect command", vim.log.levels.WARN)
    return
  end

  local result = handle:read("*a")
  handle:close()

  if result == nil then
    vim.notify("Failed to read autocorrect command output", vim.log.levels.WARN)
    return
  end

  local lines = vim.fn.split(result, "\n")
  table.insert(lines, "") --
  for i = #lines, 1, -1 do
    if lines[i] ~= "" then
      break
    end
    table.remove(lines, i)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

return M
