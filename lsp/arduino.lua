local util = require("lspconfig.util")
return {
  name = "arduino",
  cmd = {
    "/Users/pxwg-dogggie/go/bin/arduino-language-server",
    "-clangd",
    vim.fn.exepath("clangd"),
    "-cli",
    vim.fn.exepath("arduino-cli"),
    "-cli-config",
    os.getenv("ARDUINO_CONFIG"),
    "-fqbn",
    "esp32:esp32:esp32s3",
  },
  filetypes = { "arduino" },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    on_dir(util.root_pattern("*.ino")(fname))
  end,
  capabilities = {
    textDocument = {
      semanticTokens = vim.NIL,
    },
    workspace = {
      semanticTokens = vim.NIL,
    },
  },
}
