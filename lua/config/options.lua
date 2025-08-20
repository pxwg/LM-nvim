local autocmd = vim.api.nvim_create_autocmd
-- @type "telescope" | "fzf"
vim.g.picker = "telescope"
vim.g.mini_file_opened = false
vim.g.hammerspoon = true
vim.o.splitkeep = "screen"
-- Disable global spell checking, will be enabled per filetype
vim.opt.spell = false
-- vim.opt.spelllang = "en_us"
-- vim.opt.spelllang = "cjk"

-- Set up spell checking only for tex and markdown files with English checking but ignoring CJK
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "tex", "markdown", "typst" },
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.opt_local.spell = true
      vim.opt_local.spelllang = "en_us,cjk"
    end
  end,
})
vim.opt.showmode = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

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
-- vim.g.codecompanion_enabled = true
vim.g.avante_enabled = true
vim.g.copilot_chat_enabled = true
-- vim.opt.fillchars:append({ vert = "", eob = "" })
-- vim.opt.virtualedit = "all"
function Get_git_branch()
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return ""
  end
  return "[" .. branch:gsub("\n", "") .. "]"
end

vim.o.statusline = "%f %m %r %h %w %=%{v:lua.Get_git_branch()} %y %p%% %l:%c"
vim.opt.matchpairs:append("$:$")

vim.lsp.enable({
  "dictionary",
  "harper_ls",
  "html_lsp",
  "ltex",
  "lua_ls",
  "pyright",
  "rime_ls",
  "rust_analyzer",
  "texlab",
  "tinymist",
  "ts_query_ls",
  "vtsls",
  "wolfram_lsp",
  "clangd",
  "astro-ls",
})

autocmd("FileType", {
  pattern = { "markdown" },
  callback = function()
    if vim.bo.buftype == "nofile" then
      vim.opt_local.conceallevel = 2
      vim.opt_local.concealcursor = "nc"
    end
  end,
})

autocmd("BufWritePre", { pattern = { "*.md", "*.html" }, command = "set nowritebackup" })
autocmd("BufWritePost", { pattern = { "*.md", "*.html" }, command = "set writebackup" })

autocmd("OptionSet", {
  pattern = "diff",
  callback = function()
    vim.wo.wrap = true
  end,
})

vim.o.scrolloff = 5
vim.o.winborder = "none"
