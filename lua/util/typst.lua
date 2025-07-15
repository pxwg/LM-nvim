local M = {}

local ts_utils = require("nvim-treesitter.ts_utils")

M.in_math = function()
  local node = ts_utils.get_node_at_cursor()

  while node do
    local node_type = node:type()
    if node_type == "math" then
      return true
    end
    node = node:parent()
  end
  return false
end

return M
