-- Media, productivity, and advanced editing features
return {
  -- Image support for various file types
  {
    "3rd/image.nvim",
    enabled = vim.fn.has("mac") == 1,
    config = function()
      if not vim.g.started_by_firenvim then
        require("image").setup({
          backend = "kitty",
          kitty_method = "normal",
          integrations = {
            typst = { enabled = true, filetypes = { "typst" } },
            markdown = {
              enabled = false,
              clear_in_insert_mode = false,
              download_remote_images = true,
              only_render_image_at_cursor = false,
              filetypes = { "markdown", "vimwiki" },
            },
            neorg = {
              enabled = true,
              clear_in_insert_mode = false,
              download_remote_images = true,
              only_render_image_at_cursor = false,
              filetypes = { "norg" },
            },
            html = {
              enabled = false,
            },
            css = {
              enabled = true,
            },
          },
          max_width = nil,
          max_height = nil,
          max_width_window_percentage = nil,
          max_height_window_percentage = 100,
          window_overlap_clear_enabled = false,
          window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          editor_only_render_when_focused = true,
          tmux_show_only_in_active_window = true,
          hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
        })
      end
    end,
  },

  -- Image clipboard support
  {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
      filetypes = {
        codecompanion = {
          prompt_for_file_name = false,
          template = "[Image]($FILE_PATH)",
          use_absolute_path = true,
        },
      },
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

  -- Diagram support (disabled by default)
  {
    "3rd/diagram.nvim",
    enabled = false,
    dependencies = {
      "3rd/image.nvim",
    },
    opts = {
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          background = nil,
          theme = nil,
          scale = 1,
          width = nil,
          height = nil,
        },
        plantuml = {
          charset = nil,
        },
        d2 = {
          theme_id = nil,
          dark_theme_id = nil,
          scale = nil,
          layout = nil,
          sketch = nil,
        },
        gnuplot = {
          size = nil,
          font = nil,
          theme = nil,
        },
      },
    },
  },

  -- Math conceal for better math display
  {
    "elentok/math-conceal.nvim",
    config = function()
      require("math-conceal").setup()
    end,
  },

  -- Git integration with lazygit
  {
    "kdheepak/lazygit.nvim",
    cmd = {
      "LazyGit",
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
    },
  },

  -- Window flattening for better terminal integration
  {
    "willothy/flatten.nvim",
    config = true,
    lazy = false,
    priority = 1001,
  },

  -- Vim Fugitive for Git operations
  {
    "tpope/vim-fugitive",
  },

  -- Bookmarks for navigation
  {
    "MattesGroeger/vim-bookmarks",
    init = function()
      vim.g.bookmark_no_default_key_mappings = 1
      vim.g.bookmark_save_per_working_dir = 1
      vim.g.bookmark_auto_save = 1
    end,
    keys = {
      { "mm", "<Plug>BookmarkToggle", desc = "Toggle bookmark" },
      { "mi", "<Plug>BookmarkAnnotate", desc = "Annotate bookmark" },
      { "ma", "<Plug>BookmarkShowAll", desc = "Show all bookmarks" },
      { "mn", "<Plug>BookmarkNext", desc = "Next bookmark" },
      { "mp", "<Plug>BookmarkPrev", desc = "Previous bookmark" },
      { "mc", "<Plug>BookmarkClear", desc = "Clear bookmarks in buffer" },
      { "mx", "<Plug>BookmarkClearAll", desc = "Clear all bookmarks" },
    },
  },

  -- Code runner for quick execution
  {
    "michaelb/sniprun",
    branch = "master",
    build = "sh install.sh",
    config = function()
      require("sniprun").setup({})
    end,
  },

  -- Trouble for diagnostics
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    config = function()
      require("trouble").setup({
        modes = {
          test = {
            mode = "diagnostics",
            preview = {
              type = "split",
              relative = "win",
              position = "right",
              size = 0.3,
            },
          },
        },
      })
    end,
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP Definitions / references / ... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },
}