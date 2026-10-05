-- Uses Lazy's dev.path ("~") to load ~/zettypst.nvim directly.
return {
  "Project-ZetTypst/zettypst.nvim",
  name = "zettypst.nvim",
  dev = true,
  main = "zettypst",
  event = "VeryLazy",
  cmd = "Zet",
  dependencies = { "folke/snacks.nvim" },
  opts = function()
    return vim.deepcopy(require("zettypst.presets.kickstart"))
  end,
  keys = {
    { "zn", "<cmd>Zet new<cr>", desc = "[Z]ettel [N]ew" },
    { "zs", "<cmd>Zet search<cr>", desc = "[Z]ettel [S]earch" },
    { "<leader>fz", "<cmd>Zet search<cr>", desc = "[F]ind [Z]ettel" },
    { "zr", "<cmd>Zet delete<cr>", desc = "[Z]ettel [R]emove current node" },
    { "zR", "<cmd>Zet delete<cr>", desc = "[Z]ettel [R]emove current node" },
  },
}
