return {
  "pxwg/note_eng_word.nvim",
  dev = true,
  event = "VeryLazy",
  config = function()
    require("note_eng_word").setup({})
  end,
}
