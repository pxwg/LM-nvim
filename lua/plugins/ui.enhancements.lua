-- UI enhancements: navigation, visual feedback, and workspace management
return {
  -- Which-key for key binding discovery
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    cmd = "WhichKey",
    config = function()
      local wk = require("which-key")
      wk.setup({
        preset = "helix",
      })
      wk.add({
        { "<leader>f", group = "[F]ind", icon = { icon = "", color = "blue" } },
        { "<C-/>", group = "Terminal" },
        { "<leader>t", group = "[T]erminal" },
        { "<leader>g", group = "[G]it", icon = { icon = "", color = "yellow" } },
        { "<leader>c", group = "[C]ode", icon = { icon = "󰅴", color = "green" } },
        { "<leader>a", group = "[A]i", icon = { icon = "", color = "red" } },
        { "<leader>s", group = "[S]earch", icon = { icon = "", color = "green" } },
        { "<leader>e", group = "[E]xplorer Neotree (cwd)", icon = { icon = "󱏒", color = "red" } },
        { "<leader>E", group = "[E]xplorer Neotree (root)", icon = { icon = "󱏒", color = "orange" } },
        { "<leader>n", group = "[N]ote", icon = { icon = "󰎞", color = "green" } },
        {
          "<leader>b",
          group = "buffers",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
      })
    end,
  },

  -- Todo comments with highlighting
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "VeryLazy", "BufReadPre" },
    opts = {
      keywords = {
        FIX = {
          icon = " ",
          color = "error",
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
        },
        TODO = { icon = " ", color = "info" },
        PAST = { icon = " ", color = "hint", alt = { "PASSED" } },
        MARK = { icon = "󰍐 ", color = "hint", alt = { "PASSED" } },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTA = { icon = " ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    },
  },

  -- Session persistence
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select Session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },

  -- Color visualization
  {
    "norcalli/nvim-colorizer.lua",
    event = "BufRead",
    config = function() end,
  },

  -- Code outline (disabled by default)
  {
    "hedyhli/outline.nvim",
    lazy = true,
    enabled = false,
    cmd = { "Outline", "OutlineOpen" },
    keys = {
      { "<leader>cs", "<cmd>Outline<CR>", desc = "Toggle outline" },
    },
    opts = {},
  },

  -- Stay centered while navigating
  {
    "arnamak/stay-centered.nvim",
    opts = {},
  },

  -- Twilight for focused coding
  {
    "folke/twilight.nvim",
    opts = {},
  },

  -- Transparent background support
  {
    "xiyaowong/transparent.nvim",
    opts = {},
  },

  -- Kitty navigator for seamless pane switching
  {
    "knubie/vim-kitty-navigator",
    build = "cp ./*.py ~/.config/kitty/",
  },

  -- NUI for UI components
  {
    "MunifTanjim/nui.nvim",
    lazy = true,
  },

  -- Firenvim for browser integration
  {
    "glacambre/firenvim",
    build = ":call firenvim#install(0)",
    config = function()
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            priority = 0,
            selector = "textarea",
            takeover = "never",
          },
        },
      }
    end,
  },

  -- Otter for code execution in markdown
  {
    "jmbuhr/otter.nvim",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {},
  },
}