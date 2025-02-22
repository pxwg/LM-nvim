--- @type "telescope" | "fzf"
vim.g.picker = "telescope"
vim.o.splitkeep = "screen"
vim.opt.showmode = false
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
_G.mode = "error"
-- Enable break indent
vim.o.breakindent = true
vim.opt.undofile = true
vim.opt.number = true
vim.opt.relativenumber = true
-- 设置 statusline
vim.o.cmdheight = 1
vim.opt.updatetime = 100
vim.opt.clipboard = "unnamedplus"
vim.o.ttyfast = true
vim.o.lazyredraw = true

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    -- linehl = {
    --   [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    -- },
    -- numhl = {
    --   [vim.diagnostic.severity.WARN] = "WarningMsg",
    -- },
  },
})
