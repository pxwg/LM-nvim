local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)
capabilities.general.positionEncodings = { "utf-8", "utf-16" }
return {
  name = "texlab",
  cmd = { "texlab" },
  filetypes = { "tex", "bib" },
  offset_encoding = "utf-8",
  capabilities = capabilities,
}
