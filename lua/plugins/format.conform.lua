return {
  "stevearc/conform.nvim",
  event = "BufReadPre",
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format()
      end,
      desc = "[C]ode [F]ormatter",
    },
  },
  opts = {
    formatters_by_ft = {
      lua = { "stylua", "injected" },
      plaintex = { "latexindent" },
      tex = { "latexindent" },
      yml = { "yq" },
      json = { "fixjson" },
      markdown = { "autocorrect", "injected" },
      -- markdown = { "autocorrect", "prettier" },
    },
    -- format_on_save = {
    --   timeout_ms = 500,
    --   lsp_format = "fallback",
    -- },
    ignore_errors = false,
    -- Map of treesitter language to filetype
    lang_to_ft = {
      bash = "sh",
    },
    -- Map of treesitter language to file extension
    -- A temporary file name with this extension will be generated during formatting
    -- because some formatters care about the filename.
    lang_to_ext = {
      lua = "lua",
      bash = "sh",
      c_sharp = "cs",
      elixir = "exs",
      javascript = "js",
      julia = "jl",
      latex = "tex",
      markdown = "md",
      python = "py",
      ruby = "rb",
      rust = "rs",
      teal = "tl",
      typescript = "ts",
    },
  },
}
