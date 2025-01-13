local autocmd = vim.api.nvim_create_autocmd

-- set up rime_ls lsp when enter tex
autocmd("FileType", {
  pattern = "plaintex",
  callback = function()
    vim.cmd("LspStart rime_ls")
  end,
})

-- color preview
vim.api.nvim_create_autocmd("BufRead", {
  callback = function()
    vim.cmd("ColorizerAttachToBuffer")
  end,
})

-- fzf with frequency
local function log_file_access()
  local file_path = vim.fn.expand("%:p")
  if file_path ~= "" then
    os.execute("fre --add " .. file_path)
  end
end

-- Register the function to log file access on BufEnter event
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = log_file_access,
})

-- auto save cursor position
vim.api.nvim_create_autocmd("BufWinLeave", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! mkview")
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! loadview")
  end,
})
