return {
  {
    "catppuccin",
    lazy = false,
    priority = 1000000,
    name = "catppuccin",
    opts = {
      highlight_overrides = {
        all = {
          Conceal = { fg = "#f5c2e7" },
          FloatBorder = { fg = "#b4befe" },
          PmenuSel = { italic = true },
          CmpItemAbbrDeprecated = { fg = "#b4befe", strikethrough = true },
          CmpItemAbbrMatch = { fg = "#b4befe" },
          CmpItemAbbrMatchFuzzy = { fg = "#b4befe" },
          CmpItemAbbrDefault = { fg = "#b4befe" },
          CmpItemAbbr = { fg = "#bac2de" },
          -- Add the following lines
        },
      },
    },
    config = function ()
      vim.cmd("colorscheme catppuccin")
    end
  },
}
