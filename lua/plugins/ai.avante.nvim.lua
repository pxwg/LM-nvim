return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  -- lazy = false,
  version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  opts = {
    provider = "copilot",
    copilot = {
      model = "o3-mini", -- Or another valid Claude model identifier
    },
    rag_service = {
      enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
    },
  },
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
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

          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      -- enabled = false,
      opts = {
        code = {
          enabled = true,
          sign = false,
          width = "block",
          right_pad = 1,
        },
        heading = {
          enabled = false,
          sign = false,
          icons = { "", "", "", "", "", "" },
        },
        bullet = {
          enabled = false,
          icons = { "•", "◦", "▸", "▹", "▾", "▸" },
        },
        checkbox = {
          enabled = false,
        },
        win_options = { conceallevel = { rendered = 2 } },
        latex = {
          -- Turn on / off latex rendering.
          enabled = false,
          -- Additional modes to render latex.
          render_modes = true,
          -- Executable used to convert latex formula to rendered unicode.
          converter = "latex2text",
          -- Highlight for latex blocks.
          highlight = "RenderMarkdownMath",
          -- Determines where latex formula is rendered relative to block.
          -- | above | above latex block |
          -- | below | below latex block |
          position = "above",
          -- Number of empty lines above latex blocks.
          top_pad = 0,
          -- Number of empty lines below latex blocks.
          bottom_pad = 0,
        },
      },
      ft = { "markdown", "norg", "rmd", "org", "codecompanion", "Avante" },
    },
  },
}
