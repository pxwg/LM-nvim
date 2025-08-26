-- AI assistance and code generation tools
return {
  -- GitHub Copilot for code completion
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    opts = {
      suggestion = {
        enabled = not vim.g.ai_cmp,
        auto_trigger = true,
        keymap = {
          accept = "<Tab>",
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },

  -- Copilot Chat for interactive AI assistance
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    opts = {
      debug = true,
    },
    keys = {
      { "<leader>aa", function() require("CopilotChat").open() end, desc = "Open Copilot Chat" },
      { "<leader>ax", function() require("CopilotChat").close() end, desc = "Close Copilot Chat" },
      { "<leader>ar", function() require("CopilotChat").reset() end, desc = "Reset Copilot Chat" },
      { "<leader>aq", function() local input = vim.fn.input("Quick Chat: ") if input ~= "" then require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer }) end end, desc = "Quick Chat" },
    },
  },

  -- Avante for advanced AI interactions
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = false,
    version = false,
    opts = {
      provider = "copilot",
    },
    build = "make",
    dependencies = {
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "echasnovski/mini.pick",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },

  -- CodeCompanion for comprehensive AI coding assistance
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp",
      {
        "stevearc/dressing.nvim",
        opts = {},
      },
    },
    config = true,
  },

  -- MCPHub for additional AI model integrations
  {
    "Kurama622/mcp.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("mcp").setup({
        provider = {
          anthropic = {
            api_key = vim.env.ANTHROPIC_API_KEY,
          },
        },
      })
    end,
  },
}