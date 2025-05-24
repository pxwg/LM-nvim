local M = {}

function M.setup_mma_lsp()
  local root_dir = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1])

  local configs = require("lspconfig.configs")
  if not configs.wolfram_lsp then
    configs.wolfram_lsp = {
      default_config = {
        name = "wolfram-lsp",
        filetypes = "mma",
        cmd = {
          "/Applications/Wolfram.app/Contents/MacOS/WolframKernel",
          "kernel",
          "-noinit",
          "-noprompt",
          "-nopaclet",
          "-noicon",
          "-nostartuppaclets",
          "-run",
          'Needs["LSPServer`"];LSPServer`StartServer[]',
        },
        root_dir = root_dir,
        handlers = {
          ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            severity_sort = true,
            underline = true,
            virtual_text = {
              severity_limit = "Warning",
            },
            signs = {
              severity_limit = "Warning",
            },
          }),
        },
      },
    }
  end
  require("lspconfig").wolfram_lsp.setup({})
end

return M
