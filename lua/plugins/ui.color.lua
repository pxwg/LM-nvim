return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    -- event = "UIEnter",
    -- lazy = false,
    priority = 1000000,
    opts = {},
    config = function()
      -- local mocha = require("catppuccin.palettes").get_palette("mocha")
      require("catppuccin").setup({
        integrations = { blink_cmp = {
          style = "bordered",
        } },
        highlight_overrides = {
          mocha = {
            WinSeparator = { fg = "#BAC2DE" },
            Statusline = { fg = "#cdd6f4", bg = "#1e1e2f" },
            AvanteSidebarNormal = { fg = "#cdd6f4", bg = "#1e1e2f" },
            AvantePromptInputBorder = { fg = "#cdd6f4", bg = "#1e1e2f" },
            AvanteSidebarWinHorizontalSeparator = { fg = "#1e1e2f", bg = "#1e1e2f" },
            AvanteSidebarWinSeparator = { fg = "#1e1e2f", bg = "#1e1e2f" },
            -- Normal         xxx guifg=#cdd6f4 guibg=#1e1e2f
            --- Math in md
            Conceal = { fg = "#89b4fa", bg = "" },
            ["@conceal"] = { fg = "#89b4fa", bg = "" },
            -- SnacksImageMath = { fg = "#eba0ac" },
            -- --- Math in tex
            texEnvArgName = { fg = "#9399b3" },
            texOptEqual = { fg = "#7dc4e4" },
            texMathDelim = { fg = "#f9e2af" },
            -- ["@spell.latex"] = { fg = "#cdd6f4" },
            -- ["@spell.markdown"] = { fg = "#cdd6f4" },
            texMathSymbol = { fg = "#89b4fa" },
            texFileArg = { fg = "#b4befe" },
            texPartConcArgTitle = { fg = "#89b4fa", bold = true },
            texCmdRef = { fg = "#7dc4e4" },
            texCmdEnv = { fg = "#b4befe", italic = true },
            texCmdInput = { fg = "#7dc4e4", italic = true },
            texCmdClass = { fg = "#eba0ac", italic = true, bold = true },
            NoteEngDefinition = { fg = "#b4befe", italic = true },
            NoteEngWord = { fg = "#7dc4e4", bold = true },
            -- texRefArg = { fg = "#f5c2e7", bold = true },
            -- Function = { fg = "" },
            -- -- Delimiter = { fg = "" },
            -- Include = { fg = "" },
            -- Label = { fg = "" },
            -- texMathDelimZoneTD = { fg = "" },
            Special = { fg = "" },
            -- ["@function.macro"] = { fg = "" },
            -- ["@variable.parameter"] = { fg = "" },
            -- ["@string.special.path.latex"] = { fg = "" },
            --- Telescope
            TelescopeeTitle = { fg = "#1e1e2e", bg = "#eba0ac" },
            -- TelescopePromptTitle = { fg = "#1e1e2e", bg = "#f5c2e7", italic = true, bold = true },
            -- TelescopePreviewTitle = { fg = "#1e1e2e", bg = "#b4befe", bold = true },
            -- TelescopeResultsTitle = { fg = "#1e1e2e", bg = "#fab387", bold = true },
            TelescopeNormal = { fg = "#cdd6f4", bg = "#181825" },
            -- TelescopePrompt = { fg = "#f5c2e7", bg = "#1e1e2e" },
            TelescopeBorder = { fg = "#181825", bg = "#181825" },
            WhichKeyBorder = { fg = "#181825", bg = "#181825" },
            -- WhichKeyTitle = { fg = "#b4befe", bg = "#181825" },
            BlinkCmpMenuSelection = { bg = "#45475b", italic = true, bold = true },
            ["@sub_ident"] = { fg = "#94e2d6" }, -- teal: 下标标识符
            ["@sub_letter"] = { fg = "#94e2d6" }, -- teal: 下标字母
            ["@sub_number"] = { fg = "#94e2d6" }, -- teal: 下标数字
            ["@sup"] = { fg = "#fab388" }, -- peach: 上标
            ["@sup_ident"] = { fg = "#fab388" }, -- peach: 上标标识符
            ["@sup_letter"] = { fg = "#fab388" }, -- peach: 上标字母
            ["@sup_number"] = { fg = "#fab388" }, -- peach: 上标数字
            ["@symbol"] = { fg = "#74c7ed" }, -- sapphire: 符号
            ["@typ_greek_symbol"] = { fg = "#f5c2e8" }, -- pink: 希腊符号
            ["@typ_inline_dollar"] = { fg = "#f9e2b0" }, -- yellow: 内联美元符号
            ["@typ_math_delim"] = { fg = "#9399b3" }, -- overlay2: 数学分隔符
            ["@typ_math_font"] = { fg = "#eba0ad" }, -- maroon: 数学字体
            ["@typ_math_symbol"] = { fg = "#74c7ed" }, -- sapphire: 数学符号
            ["@typ_phy_symbol"] = { fg = "#a6e3a2" }, -- green: 物理符号
            ["@open1"] = { fg = "#7f849d" }, -- overlay1: 括号/分隔符
            ["@open2"] = { fg = "#7f849d" }, -- overlay1: 括号/分隔符
            ["@close1"] = { fg = "#7f849d" }, -- overlay1: 括号/分隔符
            ["@close2"] = { fg = "#7f849d" }, -- overlay1: 括号/分隔符
            ["@punctuation"] = { fg = "#9399b3" }, -- overlay2: 标点
            ["@left_paren"] = { fg = "#7f849d" }, -- overlay1: 左括号
            ["@right_paren"] = { fg = "#7f849d" }, -- overlay1: 右括号
          },
          lattie = {
            -- Normal         xxx guifg=#4c4f69 guibg=#ffffff
            --- Math in md
            -- Conceal = { fg = "#d3869b", bg = "" },
            -- ["@markup.math"] = { fg = "#4c4f69" },
            -- ["@text.math"] = { fg = "#4c4f69" },
            -- ["@markup.link.label.markdown_inline"] = { fg = "#458588" },
            -- SnacksImageMath = { fg = "#cc241d" },
            --- Math in tex
            -- texEnvArgName = { fg = "#7c6f64" },
            -- texOptEqual = { fg = "#458588" },
            -- texMathDelim = { fg = "#d79921" },
            -- texFileArg = { fg = "#83a598" },
            -- texPartConcArgTitle = { fg = "#b16286", bold = true },
            -- texCmdRef = { fg = "#458588" },
            -- texCmdEnv = { fg = "#83a598", italic = true },
            -- texCmdInput = { fg = "#458588", italic = true },
            -- texCmdClass = { fg = "#cc241d", italic = true, bold = true },
            -- texRefArg = { fg = "#d3869b", bold = true },
            -- Function = { fg = "#4c4f69" },
            -- Include = { fg = "#4c4f69" },
            -- Label = { fg = "#4c4f69" },
            -- texMathDelimZoneTD = { fg = "#4c4f69" },
            -- ["@function.macro"] = { fg = "#4c4f69" },
            -- ["@variable.parameter"] = { fg = "#4c4f69" },
            -- ["@string.special.path.latex"] = { fg = "#4c4f69" },
            --- Telescope
            TelescopeeTitle = { fg = "#ffffff", bg = "#cc241d" },
            TelescopePromptTitle = { fg = "#ffffff", bg = "#d3869b", italic = true, bold = true },
            TelescopePreviewTitle = { fg = "#ffffff", bg = "#83a598", bold = true },
            TelescopeResultsTitle = { fg = "#ffffff", bg = "#fabd2f", bold = true },
            TelescopeNormal = { fg = "#4c4f69", bg = "#f9f5d7" },
            TelescopePrompt = { fg = "#d3869b", bg = "#ffffff" },
          },
        },
      })
      vim.cmd("colorscheme catppuccin")
    end,
  },
}
