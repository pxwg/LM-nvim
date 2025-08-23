-- add lua path

package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?.lua"

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
end
vim.opt.rtp:prepend(lazypath)
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
        -- "netrwPlugin",
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

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    -- require("util.statusline")
    require("config.keymap")
    require("config.autocmd")
    require("util.history_search")
    local function get_front_window_id()
      local result = vim.fn.system("hs -c 'GetWinID()'")
      return result:match("%d+")
    end
    local log_file = vim.fn.expand("~/.local/state/nvim/windows/") .. get_front_window_id() .. "_nvim_startup.log"

    -- Record current window number and servername on Neovim startup
    local current_win = get_front_window_id()
    local servername = vim.fn.eval("v:servername")
    local file = io.open(log_file, "w")
    if file then
      file:write(current_win .. "\n" .. servername)
      file:close()
    end
  end,
})

local map = vim.keymap.set
map({ "n", "v" }, "j", "gj", { silent = true })
map({ "n", "v" }, "k", "gk", { silent = true })

-- The LSP completion handler is now managed through completion plugins like nvim-cmp
-- If you're using nvim-cmp, this manual handler configuration is not needed
-- require("util.current_function")
