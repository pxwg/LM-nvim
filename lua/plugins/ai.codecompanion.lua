return {
  "olimorris/codecompanion.nvim",
  enabled = vim.g.codecompanion_enabled or false,
  event = "VeryLazy",
  dependencies = {
    "ravitemer/mcphub.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    {
      "<leader>aa",
      function()
        vim.cmd("CodeCompanionChat")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CodeCompanionChat",
    },
    -- {
    --   "<C-c>",
    --   function()
    --     vim.cmd("CodeCompanionChat")
    --     vim.cmd("LspStart rime_ls")
    --     -- vim.cmd(":vert wincmd L")
    --   end,
    --   desc = "CodeCompanionChat",
    -- },
  },
  opts = {
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          show_result_in_chat = true, -- Show mcp tool results in chat
          make_vars = true, -- Convert resources to #variables
          make_slash_commands = true, -- Add prompts as /slash commands
        },
      },
    },
    strategies = {
      chat = {
        adapter = "copilot",
        model = "claude-sonnet-4",
      },
    },
  },
}
