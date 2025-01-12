-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)
-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.picker = "telescope"
vim.opt.showmode = false

-- Enable break indent
vim.o.breakindent = true
vim.opt.undofile = true
vim.opt.relativenumber = true
vim.o.laststatus = 0
vim.opt.updatetime = 100
vim.opt.clipboard = "unnamedplus"
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    },
    numhl = {
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = false,
    notify = false, -- get a notification when changes are found
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

require("util.dashboard")

local autocmd = vim.api.nvim_create_autocmd
-- set relativenumber when entering hello file type and unset when leaving
autocmd("FileType", {
  pattern = "hello",
  callback = function()
    vim.cmd("set norelativenumber")
  end,
})

autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "hello" then
      vim.cmd("set norelativenumber")
    end
  end,
})
autocmd("BufLeave", {
  callback = function()
    if vim.bo.filetype == "hello" then
      vim.cmd("set relativenumber")
    end
  end,
})
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    require("config.keymap")
    require("config.autocmd")
  end,
})
