local map = vim.keymap.set
local cn = require("utils.autocorrect")
require("utils.fast_keymap")

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
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })
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

--jj to escape

-- map("i", "jj", "<ESC>", { silent = true }, 500) -- 设置触发间隔时间为500毫秒
-- map_with_timeout("i", "jj", "<ESC>", { silent = true }, 500) -- 设置触发间隔时间为500毫秒

--undo and redo
map({ "n", "i" }, "<C-z>", "<C-o>:undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<C-o>:redo<CR>", { silent = true })

map({ 'n', 'i' }, '<C-a>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
  { noremap = true, silent = true, desc = "Show Signature Help" })

-- Lsp-telescope
if vim.g.picker == 'telescope' then
  map("n", "gd", "<cmd>Telescope lsp_definitions theme=cursor<cr>", { desc = "Goto [D]efinition" })
  map("n", "gr", "<cmd>Telescope lsp_references theme=cursor<cr>", { desc = "[R]eferences", nowait = true })
  map("n", "gi", "<cmd>Telescope lsp_implementations theme=cursor<cr>", { desc = "Goto [I]mplementation" })
  map("n", "gy", "<cmd>Telescope lsp_type_definitions theme=cursor<cr>", { desc = "Goto T[y]pe Definition" })
end

-- dim
map("n", "<leader>ud", "<cmd>Twilight<cr>", { silent = true, desc = "[D]im" })

--which key
map("n", "<leader>?", ":WhichKey<cr>", { desc = "Buffer Local Keymaps (which-key)" })

local function open_github_url()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.')
  local start_pos = line:sub(1, col):find("'[^']*$")
  local end_pos = line:sub(col):find("'")

  if start_pos and end_pos then
    local repo_name = line:sub(start_pos + 1, col + end_pos - 2)
    local url = "https://www.github.com/" .. repo_name
    vim.fn.system({ "open", url })
  else
    print("No valid repository name found")
  end
end

map("n", "<leader>gb", open_github_url, { noremap = true, silent = true, desc = "[B]rows Open" })
