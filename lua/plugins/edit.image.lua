return {
  {
    "3rd/image.nvim",
    -- enabled = not vim.g.started_by_firenvim,
    enabled = vim.fn.has("mac") == 1,
    events = "VeryLazy",
    config = function()
      if not vim.g.started_by_firenvim then
        require("image").setup({
          backend = "kitty",
          kitty_method = "normal",
          integrations = {
            -- Notice these are the settings for markdown files
            typst = { enabled = false, filetypes = { "typst" } },
            markdown = {
              enabled = false,
              clear_in_insert_mode = false,
              -- Set this to false if you don't want to render images coming from
              -- a URL
              download_remote_images = true,
              -- Change this if you would only like to render the image where the
              -- cursor is at
              -- I set this to true, because if the file has way too many images
              -- it will be laggy and will take time for the initial load
              only_render_image_at_cursor = false,
              -- markdown extensions (ie. quarto) can go here
              filetypes = { "markdown", "vimwiki" },
            },
            neorg = {
              enabled = true,
              clear_in_insert_mode = false,
              download_remote_images = true,
              only_render_image_at_cursor = false,
              filetypes = { "norg" },
            },
            -- This is disabled by default
            -- Detect and render images referenced in HTML files
            -- Make sure you have an html treesitter parser installed
            -- ~/github/dotfiles-latest/neovim/nvim-lazyvim/lua/plugins/treesitter.lua
            html = {
              enabled = false,
            },
            -- This is disabled by default
            -- Detect and render images referenced in CSS files
            -- Make sure you have a css treesitter parser installed
            -- ~/github/dotfiles-latest/neovim/nvim-lazyvim/lua/plugins/treesitter.lua
            css = {
              enabled = true,
            },
          },
          max_width = nil,
          max_height = nil,
          max_width_window_percentage = nil,

          -- This is what I changed to make my images look smaller, like a
          -- thumbnail, the default value is 50
          max_height_window_percentage = 100,
          max_height_window_percentage = 100,

          -- toggles images when windows are overlapped
          window_overlap_clear_enabled = false,
          window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },

          -- auto show/hide images when the editor gains/looses focus
          editor_only_render_when_focused = true,

          -- auto show/hide images in the correct tmux window
          -- In the tmux.conf add `set -g visual-activity off`
          tmux_show_only_in_active_window = true,

          -- render image files as images when opened
          hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
        })
      end
    end,
  },
  {
    "3rd/diagram.nvim",
    enabled = false,
    dependencies = {
      "3rd/image.nvim",
    },
    opts = { -- you can just pass {}, defaults below
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          background = nil, -- nil | "transparent" | "white" | "#hex"
          theme = nil, -- nil | "default" | "dark" | "forest" | "neutral"
          scale = 1, -- nil | 1 (default) | 2  | 3 | ...
          width = nil, -- nil | 800 | 400 | ...
          height = nil, -- nil | 600 | 300 | ...
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
          size = nil, -- nil | "800,600" | ...
          font = nil, -- nil | "Arial,12" | ...
          theme = nil, -- nil | "light" | "dark" | custom theme string
        },
      },
    },
  },
}
