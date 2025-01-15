local map = vim.keymap.set
local cn = require("util.autocorrect")
require("util.fast_keymap")

local function get_plugin_name()
  local bufnr = vim.api.nvim_get_current_buf()
  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local code = table.concat(content, "\n")

  local plugin_names = {}
  local seen = {}
  for name in code:gmatch('{%s*"([^"]+/[^"]+)",') do
    if not seen[name] then
      table.insert(plugin_names, name)
      seen[name] = true
    end
  end

  if #plugin_names > 1 then
    local choices = {}
    for i, name in ipairs(plugin_names) do
      table.insert(choices, string.format("%d: %s", i, name))
    end
    local choice = vim.fn.inputlist(choices)
    if choice > 0 and choice <= #plugin_names then
      return plugin_names[choice]
    else
      print("Invalid choice")
    end
  elseif #plugin_names == 1 then
    return plugin_names[1]
  else
    print("No valid plugin names")
  end
end

local function open_github_url()
  local url = "https://www.github.com/" .. get_plugin_name()
  vim.loop.spawn("open", { args = { url } })
end

_G.open_github_url = open_github_url

-- windows with hammerspoon function
local function save_and_delete_last_line()
  local ft = vim.bo.filetype
  local cursor_pos = vim.fn.getpos(".") -- 记录光标位置

  if ft == "tex" or ft == "markdown" then
    vim.cmd("w")
    local view = vim.fn.winsaveview()
    vim.api.nvim_buf_set_lines(0, -2, -1, false, {})
    vim.fn.winrestview(view)
    cn.autocorrect()
    vim.cmd("w")
  else
    vim.cmd("w")
  end
  vim.fn.setpos(".", cursor_pos) -- 恢复光标位置
end

local function is_rightmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local max_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos > max_col then
      max_col = pos
    end
  end

  return current_pos == max_col
end

local function is_leftmost_window()
  local current_win = vim.api.nvim_get_current_win()
  local current_pos = vim.api.nvim_win_get_position(current_win)[2]
  local min_col = current_pos

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local pos = vim.api.nvim_win_get_position(win)[2]
    if pos < min_col then
      min_col = pos
    end
  end

  return current_pos == min_col
end

-- switch to right window
map("n", "<C-l>", function()
  if is_rightmost_window() then
    vim.fn.system("hs -c 'focusNextWindow()'")
  else
    vim.cmd("wincmd l")
  end
end, { noremap = true, silent = true, desc = "Move to right window" })

-- same for left
map("n", "<C-h>", function()
  if is_leftmost_window() then
    vim.fn.system("hs -c 'focusPreviousWindow()'")
  else
    vim.cmd("wincmd h")
  end
end, { noremap = true, silent = true, desc = "Move to left window" })

-- move between windows
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })

--split
map("n", "<C-w>v", "", {
  noremap = true,
  silent = true,
  callback = function()
    vim.cmd("vsplit")
    vim.cmd("wincmd l")
  end,
})

-- move lines
map({ "n", "v" }, "L", "$", { silent = true })
map({ "n", "v" }, "H", "0", { silent = true })
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })

--save
map({ "n", "v", "i" }, "<C-s>", function()
  save_and_delete_last_line()
  vim.cmd("stopinsert")
end, { noremap = true, silent = true })

--better j but can't be used with esc
-- map("i", "j", 'j<ESC>:lua require("util.fast_keymap").listen_for_key(200, "j")<CR>', { noremap = true, silent = true })

--undo and redo
map({ "n", "i" }, "<C-z>", "<C-o>:undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<C-o>:redo<CR>", { silent = true })

-- signature_help
map(
  { "n" },
  "<leader>gh",
  "<cmd>lua vim.lsp.buf.signature_help()<CR>",
  { noremap = true, silent = true, desc = "Show Signature [H]elp" }
)

-- Lsp-telescope
if vim.g.picker == "telescope" then
  map("n", "gd", "<cmd>Telescope lsp_definitions theme=cursor<cr>", { desc = "Goto [D]efinition" })
  map("n", "gr", "<cmd>Telescope lsp_references theme=cursor<cr>", { desc = "[R]eferences", nowait = true })
  map("n", "gi", "<cmd>Telescope lsp_implementations theme=cursor<cr>", { desc = "Goto [I]mplementation" })
  map("n", "gy", "<cmd>Telescope lsp_type_definitions theme=cursor<cr>", { desc = "Goto T[y]pe Definition" })
end

-- dim
map("n", "<leader>ud", "<cmd>Twilight<cr>", { silent = true, desc = "[D]im" })

--which key
map("n", "<leader>?", ":WhichKey<cr>", { desc = "Buffer Local Keymaps (which-key)" })

-- enter github repo for plugins
local function set_keymap_if_in_plugins_dir()
  local current_dir = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
  local plugins_dir = vim.fn.expand("~/.config/nvim/lua/plugins")
  if current_dir == plugins_dir then
    vim.api.nvim_buf_set_keymap(
      0,
      "n",
      "gB",
      ":lua open_github_url()<CR>",
      { noremap = true, silent = true, desc = "[G]o to Plugin Url" }
    )
  end
end

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = set_keymap_if_in_plugins_dir,
})

-- Exit insert mode and clear search highlight
map("n", "<ESC>", function()
  vim.cmd("nohlsearch")
end, { noremap = true, silent = true, desc = "Exit insert mode and clear search highlight" })

-- Terminal keymaps
local terminal_keymaps = {
  { "<C-/>", "", "+Open [T]erminal" },
  { "<C-/>t", "<cmd>lua require('util.terminal').open_terminal('t')<CR>", "Open [T] Terminal Float" },
  { "<C-/>j", "<cmd>lua require('util.terminal').open_terminal('j')<CR>", "Open [J] Terminal Float" },
  { "<C-/>l", "<cmd>lua require('util.terminal').open_terminal('l')<CR>", "Open [L] Terminal Float" },
  { "<C-/>k", "<cmd>lua require('util.terminal').open_terminal('k')<CR>", "Open [K] Terminal Float" },
  { "<C-/>h", "<cmd>lua require('util.terminal').open_terminal('h')<CR>", "Open [H] Terminal Float" },
  { "<C-/>J", "<cmd>lua require('util.terminal').open_terminal_split('j')<CR>", "Open [J] Terminal Split" },
  { "<C-/>L", "<cmd>lua require('util.terminal').open_terminal_split('l')<CR>", "Open [L] Terminal Split" },
  { "<C-/>K", "<cmd>lua require('util.terminal').open_terminal_split('k')<CR>", "Open [K] Terminal Split" },
  { "<C-/>H", "<cmd>lua require('util.terminal').open_terminal_split('h')<CR>", "Open [H] Terminal Split" },
}

local terminal_keymaps_space = {
  { "<leader>t", "", "+Open [T]erminal" },
  { "<leader>tt", "<cmd>lua require('util.terminal').open_terminal('t')<CR>", "Open [T] Terminal Float" },
  { "<leader>tj", "<cmd>lua require('util.terminal').open_terminal('j')<CR>", "Open [J] Terminal Float" },
  { "<leader>tl", "<cmd>lua require('util.terminal').open_terminal('l')<CR>", "Open [L] Terminal Float" },
  { "<leader>tk", "<cmd>lua require('util.terminal').open_terminal('k')<CR>", "Open [K] Terminal Float" },
  { "<leader>th", "<cmd>lua require('util.terminal').open_terminal('h')<CR>", "Open [H] Terminal Float" },
  { "<leader>tJ", "<cmd>lua require('util.terminal').open_terminal_split('j')<CR>", "Open [J] Terminal Split" },
  { "<leader>tL", "<cmd>lua require('util.terminal').open_terminal_split('l')<CR>", "Open [L] Terminal Split" },
  { "<leader>tK", "<cmd>lua require('util.terminal').open_terminal_split('k')<CR>", "Open [K] Terminal Split" },
  { "<leader>tH", "<cmd>lua require('util.terminal').open_terminal_split('h')<CR>", "Open [H] Terminal Split" },
}

for _, keymap in ipairs(terminal_keymaps) do
  map("n", keymap[1], keymap[2], { desc = keymap[3], noremap = true, silent = true })
end

for _, keymap in ipairs(terminal_keymaps_space) do
  map("n", keymap[1], keymap[2], { desc = keymap[3], noremap = true, silent = true })
end

-- HECK: cn charactors for now

-- TODO: better delate
-- function to generate surrounding cn charactors
-- @param lhs string: The left-hand side key sequence.
-- @param rhs_c string: The right-hand side key sequence for Chinese input.
-- @param rhs_e string: The right-hand side key sequence for English input.
local function csmap(lhs, rhs_c, rhs_e)
  map("i", lhs, function()
    if require("util.rime_ls").rime_toggle_word() == "cn" then
      vim.api.nvim_feedkeys(rhs_c, "n", true)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
      return nil
    else
      vim.api.nvim_feedkeys(rhs_e, "n", true)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes([[<Left>]], true, true, true), "n", true)
      return nil
    end
  end, { noremap = true, silent = true })
end

-- function to generate single cn charactors
-- @param lhs string: The left-hand side key sequence.
-- @param rhs_c string: The right-hand side key sequence for Chinese input.
-- @param rhs_e string: The right-hand side key sequence for English input.
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
