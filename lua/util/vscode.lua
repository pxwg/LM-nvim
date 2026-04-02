local M = {}

function M.is_vscode()
  return vim.g.vscode == 1 or vim.g.vscode == true
end

return M
