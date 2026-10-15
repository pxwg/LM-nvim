return {
  name = "zettyp-lsp",
  cmd = { "zettyp-lsp" },
  -- ZetTypst returns versioned WorkspaceEdits for source-safe code actions.
  capabilities = {
    workspace = { workspaceEdit = { documentChanges = true } },
  },
  cmd_env = { TYPST_PACKAGE_PATH = vim.fn.expand("~/zettypst/.dev/packages") },
  filetypes = { "typst" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, ".zettypst")
    if root then
      on_dir(root)
    end
  end,
  init_options = { entry = "lsp.typ", hostWriteRoot = ".zettypst/cache" },
}
