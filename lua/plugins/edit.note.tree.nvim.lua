return {
  "pxwg/note-tree.nvim",
  dev = true,
  event = "VeryLazy",
  build = "make lua51",
  opts = {
    max_depth = 10,
    root = "~/personal-wiki",
  },
}
