-- LaTeX/TeX language configuration
-- Specific autocmds, keymaps, and settings for LaTeX files

local M = {}

local autocmd = vim.api.nvim_create_autocmd
local map = vim.keymap.set

M.setup = function()
  -- TeX-specific autocmds
  autocmd("FileType", {
    pattern = { "tex", "plaintex" },
    callback = function()
      -- Enable spell checking for TeX files
      if vim.bo.buftype ~= "nofile" then
        vim.opt_local.spell = true
        vim.opt_local.spelllang = "en_us,cjk"
      end
      
      -- Start rime_ls for TeX files
      vim.cmd("LspStart rime_ls")
    end,
  })

  -- TeX-specific keymaps (only active in TeX buffers)
  autocmd("FileType", {
    pattern = { "tex" },
    callback = function()
      -- Enhanced newline behavior for TeX
      map("i", "<CR>", function()
        return require("util.tex_item").insert_item()
      end, { noremap = true, silent = true, expr = true, buffer = true })
      
      map("n", "o", function()
        require("util.tex_item").insert_item_on_newline(false)
      end, { buffer = true })
      
      map("n", "O", function()
        require("util.tex_item").insert_item_on_newline(true)
      end, { buffer = true })
    end,
  })

  -- Auto-save and formatting for TeX files
  autocmd("BufWritePre", {
    pattern = { "*.tex" },
    callback = function()
      -- Custom TeX formatting logic can go here
    end,
  })

  -- Fold content above \title in TeX files
  local function fold_above_title()
    local save_cursor = vim.fn.getcurpos()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local title_line = vim.fn.search("\\\\title", "W")
    
    if title_line > 0 and title_line > 1 then
      local target_fold_line = title_line - 1
      vim.cmd("1," .. target_fold_line .. "fold")
    else
      vim.notify("\\title not found", vim.log.levels.WARN)
    end
    
    vim.fn.setpos(".", save_cursor)
  end

  -- Create user command for folding above title
  vim.api.nvim_create_user_command("FoldAboveTitle", fold_above_title, {
    nargs = 0,
    desc = "Fold all content before \\title",
  })
end

return M