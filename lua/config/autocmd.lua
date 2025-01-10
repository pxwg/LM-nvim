local autocmd = vim.api.nvim_create_autocmd

require("utils.dashboard")

-- set up rime_ls lsp when enter tex
autocmd("FileType", {
  pattern = "plaintex",
  callback = function()
    vim.cmd("LspStart rime_ls")
  end,
})

-- autocrrect
autocmd("bufwritepre", {
  pattern = "*.tex",
  callback = function()
    vim.cmd("lua require('utils.autocorrect').autocorrect()")
  end,
})
autocmd("bufwritepre", {
  pattern = "*.md",
  callback = function()
    vim.cmd("lua require('utils.autocorrect').autocorrect()")
  end,
})
