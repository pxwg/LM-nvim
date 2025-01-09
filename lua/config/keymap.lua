local map = vim.keymap.set

-- windows
map("n", "<C-h>", "<C-w>h", { silent = true })
map("n", "<C-j>", "<C-w>j", { silent = true })
map("n", "<C-k>", "<C-w>k", { silent = true })
map("n", "<C-l>", "<C-w>l", { silent = true })

-- move lines
map({ "n", "v" }, "L", "$", { silent = true })
map({ "n", "v" }, "H", "0", { silent = true })

--save
map({ "n", "i", "v" }, "<C-s>", "<ESC>:w<CR>", { silent = true })

--jj to escape
map("i", "jj", "<ESC>", { silent = true })

--undo and redo
map({ "n", "i" }, "<C-z>", "<C-o>:undo<CR>", { silent = true })
map({ "n", "i" }, "<C-r>", "<C-o>:redo<CR>", { silent = true })

map({ 'n', 'i' }, '<C-a>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
  { noremap = true, silent = true, desc = "Show Signature Help" })

-- Lsp-telescope
if vim.g.picker == 'telescope' then
  map("n", "gd", "<cmd>lua require('telescope.builtin').lsp_definitions({ reuse_win = true })<cr>",
    { desc = "Goto Definition" })
  map("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "References", nowait = true })
  map("n", "gI",
    "<cmd>lua require('telescope.builtin').lsp_implementations({ reuse_win = true })<cr>",
    { desc = "Goto Implementation" })
  map("n", "gy",
    "<cmd>lua require('telescope.builtin').lsp_type_definitions({ reuse_win = true })<cr>",
    { desc = "Goto T[y]pe Definition" })
end
