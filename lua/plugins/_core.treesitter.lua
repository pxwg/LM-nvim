-- Treesitter - configured in core but loaded as plugin
return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", event = { "LazyFile", "VeryLazy" } },
    },
    lazy = vim.fn.argc(-1) == 0,
    event = { "LazyFile", "VeryLazy" },
    version = false,
    build = ":TSUpdate",
    config = false, -- Configuration handled by core.ui
  },
}