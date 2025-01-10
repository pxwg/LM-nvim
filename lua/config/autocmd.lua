local autocmd = vim.api.nvim_create_autocmd

require("utils.dashboard")

-- set up rime_ls lsp when enter tex
autocmd("FileType", {
  pattern = "plaintex",
  callback = function()
    vim.cmd("LspStart rime_ls")
  end,
})
