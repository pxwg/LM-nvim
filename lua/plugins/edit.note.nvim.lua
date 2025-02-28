return {
  "pxwg/phonograph.nvim",
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    { "3rd/image.nvim", lazy = true, build = true }, -- Optional image support in pdf preview
  },
  branch = "feature",
  dev = true,
}
