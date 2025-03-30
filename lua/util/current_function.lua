local M = {}

function M.get_current_function()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local current_node = ts_utils.get_node_at_cursor()

  if not current_node then
    return ""
  end

  while current_node do
    local node_type = current_node:type()
    if node_type == "function_declaration" or node_type == "method_declaration" then
      return "󰊕 " .. vim.treesitter.get_node_text(current_node:field("name")[1], 0)
    end
    current_node = current_node:parent()
  end
  return ""
end

return M
