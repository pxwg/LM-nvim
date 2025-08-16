return {
  name = "tinymist",
  cmd = { "tinymist" },
  root_dir = vim.fn.getcwd(),
  filetypes = { "typst" },
  capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
  settings = {
    tinymist = {
      preview = { invertColors = "auto" },
      fontPaths = { "${workspaceFolder}/assets/fonts" },
    },
  },
}
