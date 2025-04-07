local M = {}

-- Parse markdown links in the buffer and return their positions
function M.parse_markdown_links(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local parser = vim.treesitter.get_parser(bufnr, "markdown_inline")
  if not parser then
    return {}
  end

  local tree_obj = parser:parse()
  if not tree_obj or not tree_obj[1] then
    return {}
  end

  local tree = tree_obj[1]
  local root = tree:root()
  local query = vim.treesitter.query.parse("markdown_inline", "(inline_link) @link")

  local links = {}
  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "link" then
      local start_row, start_col, _, _ = node:range()
      table.insert(links, { row = start_row, col = start_col })
    end
  end

  return links
end

-- Get or refresh the markdown links for a buffer
function M.get_buffer_links(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not vim.b[bufnr].md_links or vim.b[bufnr].md_links_stale then
    local links = M.parse_markdown_links(bufnr)
    vim.b[bufnr].md_links = links
    vim.b[bufnr].md_links_stale = false
    vim.b[bufnr].md_links_index = 0
    return links
  end

  return vim.b[bufnr].md_links
end

-- Find the next link after the current cursor position
function M.find_next_link(links, row, col)
  for i, link in ipairs(links) do
    if link.row > row or (link.row == row and link.col > col) then
      return i
    end
  end

  -- If no next link found, wrap around to the first link
  return 1
end

-- Find the previous link before the current cursor position
function M.find_prev_link(links, row, col)
  for i = #links, 1, -1 do
    local link = links[i]
    if link.row < row or (link.row == row and link.col < col) then
      return i
    end
  end

  -- If no previous link found, wrap around to the last link
  return #links
end

-- Jump to the specified link
--- @param link_index number
--- @param bufnr number
--- @param direction 0 | 1
function M.jump_to_link(link_index, bufnr, direction)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local links = vim.b[bufnr].md_links

  if not links or #links == 0 or not links[link_index] then
    return false
  end

  vim.b[bufnr].md_links_index = link_index
  vim.api.nvim_win_set_cursor(0, {
    links[((link_index + direction - 1 - 1) % #links) + 1].row + 1,
    links[((link_index + direction - 1 - 1) % #links) + 1].col + 1,
  })
  return true
end

-- Navigate to the next markdown link
function M.goto_next_link()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local links = M.get_buffer_links(bufnr)
  if #links == 0 then
    return false
  end

  local next_index = M.find_next_link(links, row, col)
  return M.jump_to_link(next_index, bufnr, 1)
end

function M.goto_prev_link()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local links = M.get_buffer_links(bufnr)
  if #links == 0 then
    return false
  end

  local prev_index = M.find_prev_link(links, row, col)
  return M.jump_to_link(prev_index, bufnr, 0)
end

return M
