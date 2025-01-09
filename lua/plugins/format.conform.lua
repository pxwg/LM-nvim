return {
  'stevearc/conform.nvim',
  event = 'BufReadPre',
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      plaintex = { "latexindent" },
      tex = { "latexindent" },
      yml = { "yq" },
    },
    format_on_save = {
      timeout_ms = 500,
      lsp_format = "fallback",
    },
  }
}
