return {
  name = "html_lsp",
  cmd = { "vscode-html-language-server" },
  root_dir = vim.fn.getcwd(),
  filetypes = { "html", "htmldjango" },
}
