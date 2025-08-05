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
    enabled = true,
    event = "VeryLazy",
    dev = true,
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
