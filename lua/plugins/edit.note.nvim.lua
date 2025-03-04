return {
  "pxwg/phonograph.nvim",
  dev = true,
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true }, -- Optional image support in pdf preview
  },
  branch = "feature",
}
