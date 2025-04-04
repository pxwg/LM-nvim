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
      plaintex = { "latexindent", "autocorrect" },
      tex = { "latexindent", "autocorrect" },
      yml = { "yq" },
      json = { "fixjson" },
      markdown = { "autocorrect", "injected" },
      rust = { "rustfmt" },
      python = function(bufnr)
        if require("conform").get_formatter_info("ruff_format", bufnr).available then
          return { "ruff_format" }
        else
          return { "isort", "black" }
        end
      end,
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
