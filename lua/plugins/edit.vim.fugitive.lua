return {
  "tpope/vim-fugitive",
  cmd = "Git",
  event = "VeryLazy",
  keys = {
    { "<leader>gd", "<cmd>Gvdiffsplit! | wincmd r<CR>", desc = "[G]it [D]iff " },
  },
}
