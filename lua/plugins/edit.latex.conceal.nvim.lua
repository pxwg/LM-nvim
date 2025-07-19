return {
  "pxwg/math-conceal.nvim",
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
}
