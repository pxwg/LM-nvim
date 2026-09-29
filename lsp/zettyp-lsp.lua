return {
  name = "zettyp-lsp",
  cmd = { vim.fn.expand("~/.local/bin/zettyp-lsp") },
  filetypes = { "typst" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, ".zettypst")
    if root then on_dir(root) end
  end,
  init_options = { entry = "lsp.typ", hostWriteRoot = ".zettypst/cache" },
}
