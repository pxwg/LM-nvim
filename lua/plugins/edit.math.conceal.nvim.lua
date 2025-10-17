return {
  {
    "dirichy/latex_concealer.nvim",
    enabled = false,
    dev = true,
    ft = { "tex", "latex" },
    opts = {},
  },
  {
    "ryleelyman/latex.nvim",
    ft = { "tex", "latex" },
    enabled = false,
    config = function()
      require("latex").setup({})
    end,
  },
  {
    "pxwg/math-conceal.nvim",
    event = "VeryLazy",
    dev = vim.fn.has("mac") == 1,
    enabled = true,
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
    },
  },
}
