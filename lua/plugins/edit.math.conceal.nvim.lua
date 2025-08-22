return {
  {
    "dirichy/latex_concealer.nvim",
    enabled = false,
    ft = { "tex", "latex" },
    opts = {},
    config = true,
  },
  {
    "pxwg/math-conceal.nvim",
    event = "VeryLazy",
    dev = vim.fn.has("mac") == 1,
    build = "make lua51",
    main = "math-conceal",
    --- @type LaTeXConcealOptions
    opts = {
      enabled = true,
      conceal = {
        "greek",
        "script",
        "math",
        "font",
        "delim",
        "phy",
      },
      ft = { "*.tex", "*.md", "*.typ" },
    },
  },
}
