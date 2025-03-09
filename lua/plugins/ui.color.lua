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
            --- Math in md
            Conceal = { fg = "#f5c2e7", bg = "" },
            ["@markup.math"] = { fg = "" },
            ["@text.math"] = { fg = "" },
            ["@markup.link.label.markdown_inline"] = { fg = "#7dc4e4" },
            SnacksImageMath = { fg = "#eba0ac" },
            --- Math in tex
            texEnvArgName = { fg = "#9399b3" },
            texOptEqual = { fg = "#7dc4e4" },
            texMathDelim = { fg = "#f9e2af" },
            texFileArg = { fg = "#b4befe" },
            texPartConcArgTitle = { fg = "#89b4fa", bold = true },
            texCmdRef = { fg = "#7dc4e4" },
            texCmdEnv = { fg = "#b4befe", italic = true },
            texCmdInput = { fg = "#7dc4e4", italic = true },
            texCmdClass = { fg = "#eba0ac", italic = true, bold = true },
            texRefArg = { fg = "#f5c2e7", bold = true },
            Function = { fg = "" },
            -- Delimiter = { fg = "" },
            Include = { fg = "" },
            Label = { fg = "" },
            texMathDelimZoneTD = { fg = "" },
            -- Special = { fg = "" },
            ["@function.macro"] = { fg = "" },
            ["@variable.parameter"] = { fg = "" },
            ["@string.special.path.latex"] = { fg = "" },
            --- Telescope
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
