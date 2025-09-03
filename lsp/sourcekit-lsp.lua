return {
  name = "sourcekit-lsp",
  cmd = { "sourcekit-lsp" },
  filetypes = { "swift", "objective-c", "objective-cpp" },
  root_dir = function(fname)
    return require("lspconfig.util").root_pattern("Package.swift", "compile_commands.json", ".git")(fname)
  end,
}
