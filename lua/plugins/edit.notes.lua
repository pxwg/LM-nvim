-- Note-taking and knowledge management tools
return {
  -- Phonograph for note management
  {
    "pxwg/phonograph.nvim",
    dev = vim.fn.has("mac") == 1,
    enabled = vim.fn.has("mac") == 1,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      { "3rd/image.nvim", lazy = true, build = true, enabled = not vim.g.started_by_firenvim and not vim.g.neovide },
    },
    branch = "feature",
  },

  -- Side notes for contextual information
  {
    "pxwg/sidenote.nvim",
    dev = true,
    enabled = false,
    event = "VeryLazy",
    keys = { { "<C-n>", ":SidenoteInsert<CR>", desc = "Insert SideNote" } },
    opts = {
      virtual_text = { hl_group = "Type", prefix = "●", upper_connector = "╭─", lower_connector = "╰─ " },
    },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "copilot-chat", "markdown" },
        callback = function()
          vim.cmd("SidenoteRestoreAll")
        end,
      })
    end,
  },

  -- Note tree for hierarchical organization
  {
    "pxwg/note-tree.nvim",
    dev = true,
    enabled = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>no", ":NoteTreeOpen<CR>", desc = "Open Note Tree" },
      { "<leader>nc", ":NoteTreeClose<CR>", desc = "Close Note Tree" },
    },
  },

  -- Anki integration for spaced repetition
  {
    "pxwg/note_anki.nvim",
    dev = true,
    enabled = false,
    event = "VeryLazy",
    keys = {
      { "<leader>na", ":AnkiAdd<CR>", desc = "Add to Anki" },
      { "<leader>ns", ":AnkiSync<CR>", desc = "Sync Anki" },
    },
  },

  -- Mind mapping
  {
    "phaazon/mind.nvim",
    branch = "v2.2",
    dependencies = { "nvim-lua/plenary.nvim" },
    enabled = false,
    config = function()
      require("mind").setup()
    end,
  },

  -- Kiwi for simple wiki functionality
  {
    "serenevoid/kiwi.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    enabled = false,
    opts = {
      {
        name = "work",
        path = "/home/username/work_wiki",
      },
      {
        name = "personal",
        path = "/home/username/personal_wiki",
      },
    },
    keys = {
      { "<leader>ww", ":lua require('kiwi').open_wiki_index()<cr>", desc = "Open Wiki index" },
      { "<leader>wp", ":lua require('kiwi').open_wiki_index('personal')<cr>", desc = "Open Personal Wiki index" },
      { "T", ":lua require('kiwi').todo.toggle()<cr>", desc = "Toggle Markdown Task" },
    },
    lazy = true,
  },

  -- Zoticite for Zotero integration
  {
    "pxwg/zoticite",
    dev = true,
    enabled = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("zoticite").setup({
        zotero_db_path = "~/Zotero/zotero.sqlite",
      })
    end,
    keys = {
      { "<leader>zo", "<cmd>Zoticite<cr>", desc = "Open Zoticite" },
    },
  },

  -- Zhihu integration for content publishing
  {
    "pxwg/zhihu.on.nvim",
    dev = true,
    enabled = false,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("zhihu.on.nvim").setup()
    end,
    keys = {
      { "<leader>zh", "<cmd>ZhihuPublish<cr>", desc = "Publish to Zhihu" },
    },
  },
}