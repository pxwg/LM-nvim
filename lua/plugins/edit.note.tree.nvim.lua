return {
  "pxwg/note-tree.nvim",
  dev = true,
  enabled = vim.fn.has("mac") == 1,
  event = "VeryLazy",
  build = "make lua51",
  opts = {
    max_depth = 10,
    root = "~/personal-wiki",
  },
}
