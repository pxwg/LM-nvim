return {
  name = "zettyp-lsp",
  cmd = { vim.fn.expand("~/zettypst/target/debug/zettyp-lsp") },
  cmd_env = { TYPST_PACKAGE_PATH = vim.fn.expand("~/zettypst/.dev/packages") },
  filetypes = { "typst" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, ".zettypst")
    if root then on_dir(root) end
  end,
  init_options = { entry = "lsp.typ", hostWriteRoot = ".zettypst/cache" },
}
