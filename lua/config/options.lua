-- @type "telescope" | "fzf"
vim.g.picker = "telescope"
vim.g.hammerspoon = true
vim.o.splitkeep = "screen"
vim.opt.spell = true
-- vim.opt.spelllang = "en_us"
vim.opt.spelllang = "cjk"
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
vim.opt.updatetime = 1
vim.opt.clipboard = "unnamedplus"
vim.o.ttyfast = true
vim.o.lazyredraw = true
vim.opt.laststatus = 3
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.conceallevel = 2
vim.g.tex_conceal = "abdmg"
vim.diagnostic.config({
  virtual_text = true,
  virtual_lines = { current_line = true },
  underline = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})
vim.opt.foldmethod = "marker"
vim.opt.relativenumber = false
-- set WinSeparator to " "
vim.cmd([[highlight WinSeparator guifg=#181825]])
-- vim.opt.fillchars:append({ vert = "", eob = "" })
-- vim.opt.virtualedit = "all"
