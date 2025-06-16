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
    {
      "<C-c>",
      function()
        vim.cmd("CodeCompanionChat")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CodeCompanionChat",
    },
  },
  opts = {
    strategies = {
      chat = {
        adapter = "copilot",
        model = "claude-sonnet-4-20250514",
      },
    },
  },
}
