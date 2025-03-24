-- HECK: cn charactors for now

local map = vim.keymap.set

-- TODO: better delate
-- function to generate surrounding cn charactors
---@param lhs string: The left-hand side key sequence.
---@param rhs_c string: The right-hand side key sequence for Chinese input.
---@param rhs_e string: The right-hand side key sequence for English input.
local function csmap(lhs, rhs_c, rhs_e)
  map("i", lhs, function()
    if require("util.rime_ls").rime_toggle_word() == "cn" then
      vim.api.nvim_feedkeys(rhs_c, "n", true)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
      return nil
    else
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local prev_char = col > 0 and line:sub(col, col) or ""
      if prev_char == " " then
        vim.api.nvim_feedkeys(rhs_e, "n", true)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
      else
        vim.api.nvim_feedkeys(rhs_e:sub(1, 1), "n", true)
      end
      return nil
    end
  end, { noremap = true, silent = true })
end

-- function to generate single cn charactors
---@param lhs string: The left-hand side key sequence.
---@param rhs_c string: The right-hand side key sequence for Chinese input.
---@param rhs_e string: The right-hand side key sequence for English input.
local function cmap(lhs, rhs_c, rhs_e)
  map("i", lhs, function()
    if require("util.rime_ls").rime_toggle_word() == "cn" then
      vim.api.nvim_feedkeys(rhs_c, "n", true)
      return nil
    else
      vim.api.nvim_feedkeys(rhs_e, "n", true)
      return nil
    end
  end, { noremap = true, silent = true })
end

csmap('"', "“”", '""')
csmap("'", "‘’", "''")
csmap("<", "《》", "<>")

cmap(";", "；", ";")
cmap(",", "，", ",")
cmap(".", "。", ".")
cmap("?", "？", "?")
cmap("!", "！", "!")
cmap(":", "：", ":")
cmap("\\", "、", "\\")

map("i", "<C-\\>", "\\", { noremap = true, silent = true })
