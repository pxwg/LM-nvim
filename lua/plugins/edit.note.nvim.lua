return {
  "pxwg/phonograph.nvim",
  dev = vim.fn.has("mac") == 1,
  enabled = false,
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true, enabled = not vim.g.started_by_firenvim and not vim.g.neovide }, -- Optional image support in pdf preview
  },
  branch = "feature",
}
