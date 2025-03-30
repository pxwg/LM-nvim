return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "main",
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
  },
  build = "make tiktoken", -- Only on MacOS or Linux

  keys = {
    {
      "<leader>aa",
      function()
        vim.cmd("CopilotChatToggle")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
    {
      "<C-c>",
      function()
        vim.cmd("CopilotChatToggle")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
  },

  opts = function()
    return {
      auto_insert_mode = false, -- Automatically enter insert mode when opening window and on new prompt
      debug = false, -- Enable debugging
      reset = {
        normal = "<C-b>",
        insert = "<C-b>",
      },
      complete = {
        detail = "Use @<localleader>s or /<localleader>s for options.",
        insert = "<localleader>s",
      },
      question_header = "󰩃  Doggie  ",
      answer_header = "  Copilot ",
      model = "claude-3.7-sonnet-thought", -- Set Claude model as default
      window = {
        layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
        width = 0.3, -- fractional width of parent, or absolute width in columns when > 1
      },
    }
  end,
  cmd = "CopilotChat",
  config = function(_, opts)
    local chat = require("CopilotChat")

    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "copilot-chat",
      callback = function()
        vim.opt_local.relativenumber = false
        vim.opt_local.number = false
        -- vim.cmd("LspStart rime_ls")
      end,
    })

    chat.setup(opts)
  end,
}
