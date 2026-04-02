local capabilities = require("util.lsp_capabilities").make()
capabilities.general.positionEncodings = { "utf-8", "utf-16" }
return {
  name = "texlab",
  cmd = { "texlab" },
  filetypes = { "tex", "bib" },
  -- offset_encoding = "utf-8",
  -- capabilities = capabilities,
}
