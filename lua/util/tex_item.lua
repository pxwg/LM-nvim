local M = {}

local tex = require("util.latex")

function M.insert_item()
  local line = vim.api.nvim_get_current_line()
  local insert_line = vim.fn.line(".")

  if line:match("\\item") and tex.in_item() then
    local prev_line = vim.fn.getline(insert_line)
    local indent = prev_line:match("^%s*")

    vim.schedule(function()
      vim.fn.append(insert_line, indent .. "\\item ")
      vim.api.nvim_win_set_cursor(0, { insert_line + 1, 1000000 })
    end)
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", true)
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
