local map = vim.keymap.set
local cn = require("util.autocorrect")
require("util.fast_keymap")

-- open_github_url for plugin reading
local function open_github_url()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".")
  local start_pos = line:sub(1, col):find("'[^']*$")
  local end_pos = line:sub(col):find("'")

  if start_pos and end_pos then
    local repo_name = line:sub(start_pos + 1, col + end_pos - 2)
    -- 修正解析仓库名称的逻辑
    repo_name = repo_name:match("([%w%.%-_/]+)")
    local url = "https://www.github.com/" .. repo_name
    os.execute("open " .. url)
  else
    print("No valid repository name found")
  end
end

-------------windows----------------
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

map("n", "<leader>gb", open_github_url, { noremap = true, silent = true, desc = "[B]rows Open" })

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
