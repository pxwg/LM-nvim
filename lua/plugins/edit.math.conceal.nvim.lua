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
    -- enabled = false,
    -- build = "make lua51",
    main = "math-conceal",
    opts = {
      ft = { "plaintex", "tex", "context", "bibtex", "typst", "markdown" },
      image_conceal = {
        enabled = false,
        ft = { "typst" },
        typst = {
          typst_binary = "typst",
          ppi = 300,
          math_baseline_pt = 11,
          styling_type = "colorscheme",
          color = nil,
          header = "",
          compiler_args = {},
          conceal_in_normal = false,
        },
      },
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
