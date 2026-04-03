local M = {}

M.in_math = function()
  local node = vim.treesitter.get_node()

  while node do
    if node:type() == "math" then
      return true
    end
    node = node:parent()
  end

  return false
end

return M
