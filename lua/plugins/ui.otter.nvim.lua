require("util.lazyfile").lazy_file()
return {
  "jmbuhr/otter.nvim",
  enabled = false,
  event = { "LazyFile", "VeryLazy" },
  -- event = "VeryLazy",
  ft = { "markdown", "Avante", "copilot-chat" },
  -- dependencies = {
  --   "nvim-treesitter/nvim-treesitter",
  -- },
}
