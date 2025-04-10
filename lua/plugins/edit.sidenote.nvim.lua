return {
  "pxwg/sidenote.nvim",
  dev = true,
  enabled = false,
  event = "VeryLazy",
  keys = { { "<C-n>", ":SidenoteInsert<CR>", desc = "Insert SideNote" } },
  --- @type SideNoteOpts
  opts = {
    virtual_text = { hl_group = "Type", prefix = "●", upper_connector = "╭─", lower_connector = "╰─ " },
  },
  config = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "copilot-chat", "markdown" },
      callback = function()
        vim.cmd("SidenoteRestoreAll")
        -- mkdMath()
      end,
    })
  end,
  -- lazy = true,
  -- cmd = "SidenoteInsert",
}
