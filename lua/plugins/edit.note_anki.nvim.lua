return {
  "pxwg/note_eng_word.nvim",
  enabled = vim.fn.has("mac") == 1,
  dev = true,
  event = "VeryLazy",
  config = function()
    require("note_eng_word").setup({})
  end,
}
