local pyright_capabilities = require("util.lsp_capabilities").make()

return {
  name = "pyright",
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  capabilities = pyright_capabilities,
  root_dir = vim.fn.getcwd(),
  settings = {
    python = {
      venvPath = ".",
      venv = ".venv",
      analysis = {
        diagnosticMode = "off",
        typeCheckingMode = "off",
      },
    },
  },
}
