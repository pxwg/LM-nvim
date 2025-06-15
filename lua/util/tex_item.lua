local M = {}

local tex = require("util.latex")

function M.insert_item()
  local line_content = vim.api.nvim_get_current_line()
  local current_line_num = vim.fn.line(".") -- 1-indexed

  -- If the line is just \item with optional whitespace
  if line_content:match("^%s*\\item%s*$") then
    vim.schedule(function()
      -- vim.api.nvim_buf_set_lines(0, current_line_num - 1, current_line_num, false, { " " })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-o>dF\\", true, false, true), "n", true)
    end)
  else
    if line_content:match("\\item") and tex.in_item() then
      local indent = line_content:match("^%s*") -- Indent from the current line

      vim.schedule(function()
        vim.fn.append(current_line_num, indent .. "\\item ")
        local new_item_text_length = vim.fn.strchars(indent .. "\\item ")
        vim.api.nvim_win_set_cursor(0, { current_line_num + 1, new_item_text_length })
      end)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
    end
  end
end

function M.insert_item_on_newline(is_above)
  local line = vim.api.nvim_get_current_line()
  local insert_line = vim.fn.line(".")

  if line:match("\\item") and tex.in_item() then
    local prev_line = vim.fn.getline(insert_line)
    local indent = prev_line:match("^%s*")
    if is_above then
      vim.fn.append(insert_line - 1, indent .. "\\item ")
      vim.api.nvim_win_set_cursor(0, { insert_line, 1000000 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", true)
    else
      vim.fn.append(insert_line, indent .. "\\item ")
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("a", true, false, true), "n", true)
    end
  else
    -- Simulate 'o' or 'O' based on the is_above flag
    if is_above then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("O", true, false, true), "n", true)
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o", true, false, true), "n", true)
    end
  end
end

return M
