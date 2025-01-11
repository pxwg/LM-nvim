local autocmd = vim.api.nvim_create_autocmd

require("util.dashboard")

-- set up rime_ls lsp when enter tex
autocmd("FileType", {
  pattern = "plaintex",
  callback = function()
    vim.cmd("LspStart rime_ls")
  end,
})

-- set relativenumber when entering hello file type and unset when leaving
autocmd("FileType", {
  pattern = "hello",
  callback = function()
    vim.cmd("set relativenumber!")
  end,
})

autocmd("BufLeave", {
  callback = function()
    if vim.bo.filetype == "hello" then
      vim.cmd("set norelativenumber!")
    end
  end,
})
