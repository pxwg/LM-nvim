vim.loader.enable(false)

vim.opt.swapfile = false
vim.opt.shadafile = "NONE"

vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.expand("~/.local/share/nvim/mason/bin/")
package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?/init.lua"
package.path = package.path .. ";" .. "/Users/pxwg-dogggie/.luarocks/share/lua/5.1/?.lua"
package.cpath = package.cpath .. ";" .. "/Users/pxwg-dogggie/.luarocks/lib/lua/5.1/?.so"

local config_dir = vim.fn.expand("~/.config/nvim")
vim.opt.rtp:prepend(config_dir)

local lazy_root = vim.fn.expand("~/.local/share/nvim/lazy")
for _, plugin_dir in ipairs(vim.fn.globpath(lazy_root, "*", false, true)) do
  vim.opt.rtp:append(plugin_dir)
end
