return {
  "pxwg/sidenote.nvim",
  dev = true,
  event = "VeryLazy",
  keys = { { "<C-n>", ":SidenoteInsert<CR>", desc = "Insert SideNote" } },
  --- @type SideNoteOpts
  opts = {
    virtual_text = { hl_group = "Type", prefix = "●", upper_connector = "╭─", lower_connector = "╰─ " },
  },
  -- lazy = true,
  -- cmd = "SidenoteInsert",
}
