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

-- The DSL owns the whole comment line, including whitespace and string values.
-- Locate its prefix, then let the server's marker token decide whether it is DSL.
M.in_dsl = function()
  if vim.bo.filetype ~= "typst" then
    return false
  end
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local line = vim.api.nvim_get_current_line()
  local prefix = line:find("%S")
  if not prefix or line:sub(prefix, prefix + 2) ~= "///" or line:sub(prefix + 3, prefix + 3) == "/" then
    return false
  end
  for _, token in ipairs(vim.lsp.semantic_tokens.get_at_pos(0, row, prefix - 1) or {}) do
    if token.type == "zkDslMarker" and token.modifiers.zkDsl then
      return true
    end
  end
  return false
end

return M
