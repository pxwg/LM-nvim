-- Reuse the default wiki's pinned plugin and project composition.
return {
  name = "wiki-ocaml",
  dir = require("util.wiki").root() .. "/.zettypst/nvim/plugin",
  lazy = true,
  event = "VeryLazy",
  cmd = { "Zet", "WikiZet" },
  dependencies = { "folke/snacks.nvim" },
  config = function()
    require("util.wiki").setup()
  end,
  keys = {
    { "zn", "<cmd>Zet new<cr>", desc = "[Z]ettel [N]ew" },
    { "zs", "<cmd>Zet search<cr>", desc = "[Z]ettel [S]earch" },
    { "<leader>fz", "<cmd>Zet search<cr>", desc = "[F]ind [Z]ettel" },
    { "zr", "<cmd>Zet delete<cr>", desc = "[Z]ettel [R]emove current node" },
    { "zR", "<cmd>Zet delete<cr>", desc = "[Z]ettel [R]emove current node" },
  },
}
