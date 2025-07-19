local capabilities = vim.lsp.protocol.make_client_capabilities()

return {
  name = "dictionary",
  cmd = { vim.fn.expand("~/dictionary_lsp/target/release/dictionary_lsp") },
  autostart = true,
  single_file_support = true,
  capabilities = capabilities,
}
