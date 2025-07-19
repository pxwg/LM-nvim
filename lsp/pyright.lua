local pyright_capabilities = vim.lsp.protocol.make_client_capabilities()
pyright_capabilities = require("blink.cmp").get_lsp_capabilities(pyright_capabilities)

return {
  name = "pyright",
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  capabilities = pyright_capabilities,
  root_dir = vim.fn.getcwd(),
  settings = {
    python = {
      analysis = {
        diagnosticMode = "off",
        typeCheckingMode = "off",
      },
    },
  },
}
