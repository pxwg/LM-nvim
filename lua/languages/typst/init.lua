-- Typst language configuration
-- Specific autocmds, keymaps, and settings for Typst files

local M = {}

local autocmd = vim.api.nvim_create_autocmd

M.setup = function()
  -- Typst-specific autocmds
  autocmd("FileType", {
    pattern = { "typst" },
    callback = function()
      -- Enable spell checking for Typst files
      if vim.bo.buftype ~= "nofile" then
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us,cjk"
      end
    end,
  })

  -- Typst-specific settings and keymaps can be added here
  -- Currently, most Typst functionality is handled through plugins
  -- This module provides a place for future Typst-specific configurations
end

return M