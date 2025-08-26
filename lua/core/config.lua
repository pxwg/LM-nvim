-- Core configuration settings
-- Basic vim options and settings extracted from config/options.lua

local M = {}

-- Core vim settings that don't depend on specific filetypes or plugins
M.setup = function()
  -- Global settings
  vim.g.picker = "telescope"
  vim.g.mini_file_opened = false
  vim.g.hammerspoon = true
  
  -- Core editor settings
  vim.o.splitkeep = "screen"
  vim.opt.showmode = false
  vim.o.tabstop = 2
  vim.opt.softtabstop = 2
  vim.o.shiftwidth = 2
  vim.o.expandtab = true
  
  -- Global mode (error handling)
  _G.mode = "error"
  
  -- Essential editor options
  vim.o.breakindent = true
  vim.opt.undofile = true
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.o.cmdheight = 1
  vim.opt.updatetime = 1
  vim.opt.clipboard = "unnamedplus"
  vim.o.ttyfast = true
  vim.o.lazyredraw = true
  vim.opt.laststatus = 3
  vim.opt.splitright = true
  vim.opt.splitbelow = true
  vim.opt.conceallevel = 2
  
  -- Spell checking - disable global, will be enabled per filetype
  vim.opt.spell = false
  
  -- TeX concealment
  vim.g.tex_conceal = "abdmg"
  
  -- Basic diagnostic configuration
  vim.diagnostic.config({
    virtual_text = true,
    virtual_lines = { current_line = true },
    underline = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "●",
        [vim.diagnostic.severity.WARN] = "●",
        [vim.diagnostic.severity.HINT] = "●",
        [vim.diagnostic.severity.INFO] = "●",
      },
      linehl = {},
      numhl = {},
    },
    update_in_insert = false,
    float = {
      focusable = false,
      style = "minimal",
      border = "rounded",
      source = "always",
      header = "",
      prefix = "",
    },
  })
  
  -- Scrolling and borders
  vim.o.scrolloff = 5
  vim.o.winborder = "none"
  
  -- Status line with git branch
  vim.o.statusline = "%f %m %r %h %w %=%{v:lua.Get_git_branch()} %y %p%% %l:%c"
  vim.opt.matchpairs:append("$:$")
  
  -- Enable LSP servers
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
end

-- Git branch function for statusline
function Get_git_branch()
  local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return ""
  end
  return "[" .. branch:gsub("\n", "") .. "]"
end

-- Make the function global for statusline
_G.Get_git_branch = Get_git_branch

return M