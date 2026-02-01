-- add lua path

vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.local/share/nvim/mason/bin/")
package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?.lua"
--- .so file
package.cpath = package.cpath .. ";" .. "/Users/pxwg-dogggie/.luarocks/lib/lua/5.1/?.so"

_G.HOMEPARH = vim.fn.expand("$HOME")

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
  package.path = package.path .. ";/Users/pxwg-dogggie/.local/share/nvim/lazy/CopilotChat.nvim/lua/?.lua"
end
vim.opt.rtp:prepend(lazypath)

local status_ok, lazy_module = pcall(require, "util.lazyfile")
if not status_ok then
  vim.notify("Critical Error: Failed to load util.lazyfile\n" .. lazy_module, vim.log.levels.ERROR)
  return
end

local setup_ok, setup_err = pcall(lazy_module.lazy_file)
if not setup_ok then
  vim.notify("Lazy Setup Error:\n" .. setup_err, vim.log.levels.ERROR)
end

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
require("config.options")
-- Setup lazy.nvim
require("lazy").setup({
  dev = {
    -- Directory where you store your local plugin projects. If a function is used,
    -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
    ---@type string | fun(plugin: LazyPlugin): string
    path = "~",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
    fallback = false, -- Fallback to git when local plugin doesn't exist
  },
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  -- install = { colorscheme = { "catppuccin" } },
  -- automatically check for plugin updates
  checker = { enabled = false },
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = true,
    notify = false, -- get a notification when changes are found
  },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

local autocmd = vim.api.nvim_create_autocmd

-- set relativenumber when entering hello file type and unset when leaving
require("mini.hues").setup({ background = "#11262d", foreground = "#c0c8cc", saturation = "lowmedium" })
-- vim.api.nvim_set_hl(0, "Normal", { bg = "#11262d" })
vim.api.nvim_set_hl(0, "@typ_inline_dollar.typst", { link = "Comment" })
vim.api.nvim_set_hl(0, "@conceal_dollar", { link = "Comment" })

autocmd("UIEnter", {
  callback = function()
    vim.cmd("setlocal relativenumber")
    vim.cmd("setlocal number")
  end,
})

autocmd("FileType", {
  pattern = "hello",
  callback = function()
    vim.cmd("setlocal norelativenumber")
    vim.cmd("setlocal nonumber")
  end,
})

require("util.dashboard")
-- autocmd("BufLeave", {
--   callback = function()
--     if vim.bo.filetype == "hello" then
--       vim.cmd("setlocal relativenumber")
--       vim.cmd("setlocal number")
--     end
--   end,
-- })
vim.api.nvim_create_user_command("SideNoteMode", function()
  require("util.sidenote").adjust_ui_for_window_size()
  vim.cmd("edit " .. vim.fn.expand("~/personal-wiki/Side_Note.md"))
  vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")
end, { desc = "Adjust UI for Side Note Mode" })

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    -- require("util.statusline")
    require("config.keymap")
    require("config.autocmd")
    require("util.history_search")
    local hs = require("util.hammerspoon")
    if hs.hammerspoon_enabled() then
      hs.hammerspoon_load()
    end
  end,
})

local map = vim.keymap.set
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })

-- The LSP completion handler is now managed through completion plugins like nvim-cmp
-- If you're using nvim-cmp, this manual handler configuration is not needed
-- require("util.current_function")
local luarocks_path = vim.fn.expand("~/.luarocks/share/lua/5.1/?.lua")
local luarocks_cpath = vim.fn.expand("~/.luarocks/lib/lua/5.1/?.so")

-- 添加到 package.path 和 package.cpath
package.path = package.path .. ";" .. luarocks_path
package.cpath = package.cpath .. ";" .. luarocks_cpath
