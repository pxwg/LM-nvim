return {
  "pxwg/phonograph.nvim",
  dev = true,
  enabled = not vim.g.neovide and not vim.g.started_by_firenvim,
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true }, -- Optional image support in pdf preview
  },
  branch = "feature",
}
