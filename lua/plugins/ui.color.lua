return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- event = "UIEnter",
    -- lazy = false,
    priority = 1000000,
    opts = {},
    config = function()
      require("catppuccin").setup({
        integrations = { blink_cmp = true },
        highlight_overrides = {
          mocha = {
            -- Normal         xxx guifg=#cdd6f4 guibg=#1e1e2e
            Conceal = { fg = "#f5c2e7" },
            SnacksImageMath = { fg = "#cdd6f4" },
            TelescopeeTitle = { fg = "#1e1e2e", bg = "#eba0ac" },
            TelescopePromptTitle = { fg = "#1e1e2e", bg = "#f5c2e7", italic = true, bold = true },
            TelescopePreviewTitle = { fg = "#1e1e2e", bg = "#b4befe", bold = true },
            TelescopeResultsTitle = { fg = "#1e1e2e", bg = "#fab387", bold = true },
            TelescopeNormal = { fg = "#cdd6f4", bg = "#181825" },
            TelescopePrompt = { fg = "#f5c2e7", bg = "#1e1e2e" },
            TelescopeBorder = { fg = "#1e1e2e", bg = "#181825" },
            WhichKeyBorder = { fg = "#181825", bg = "#181825" },
            WhichKeyTitle = { fg = "#b4befe", bg = "#181825" },
            BlinkCmpMenuSelection = { fg = "#1e1e2e", bg = "#7dc4e4", italic = true, bold = true },
            CmpItemAbbrDeprecated = { fg = "#b4befe", strikethrough = true },
            CmpItemAbbrMatch = { fg = "#b4befe" },
            CmpItemAbbrMatchFuzzy = { fg = "#b4befe" },
            CmpItemAbbrDefault = { fg = "#b4befe" },
            CmpItemAbbr = { fg = "#bac2de" },
          },
        },
      })
      vim.cmd("colorscheme catppuccin")
    end,
  },
}
