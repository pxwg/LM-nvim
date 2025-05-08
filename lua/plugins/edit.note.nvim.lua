return {
  "pxwg/phonograph.nvim",
  dev = true,
  event = "VeryLazy",
  enabled = not vim.g.started_by_firenvim and not vim.g.neovide and vim.fn.has("gui") == 0,
  dependencies = {
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true, enabled = not vim.g.started_by_firenvim and not vim.g.neovide }, -- Optional image support in pdf preview
  },
  branch = "feature",
}
