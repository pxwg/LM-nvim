return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  enabled = vim.g.avante_enabled or false,
  keys = {
    {
      "<leader>aa",
      function()
        vim.cmd("AvanteAsk")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
  },
  -- lazy = false,
  version = false,
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  opts = {
    provider = "copilot",
    -- provider = "deepseek",
    -- provider = "claude",
    cursor_applying_provider = "deepseek",
    providers = {
      copilot = {
        -- model = "claude-sonnet-4",
      },
      deepseek = {
        __inherited_from = "openai",
        api_key_name = "DEEPSEEK_API_KEY",
        endpoint = "https://api.deepseek.com",
        model = "deepseek-chat",
      },
      claude = {
        endpoint = "https://api.gptsapi.net",
        model = "claude-3-7-sonnet-20250219",
        api_key_name = "CLAUDE_API_KEY",
        extra_request_body = {
          temperature = 0.75,
        },
      },
    },
    rag_service = {
      enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
    },
    windows = {
      sidebar_header = {
        enabled = false,
      },
    },
    behaviour = {
      enable_token_counting = false,
      enable_cursor_planning_mode = true,
    },
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      -- print("Avante system prompt: ", hub and hub:get_active_servers_prompt() or "")
      return hub and hub:get_active_servers_prompt() or ""
    end,
    -- Using function prevents requiring mcphub before it's loaded
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
        -- {
        --   name = "fetch_url",
        --   description = "Fetch content from a web URL and provide it as context to the model",
        --   param = {
        --     type = "table",
        --     fields = {
        --       {
        --         name = "url",
        --         description = "URL to fetch content from (will auto-prepend https:// if protocol is missing)",
        --         type = "string",
        --         optional = false,
        --       },
        --       {
        --         name = "timeout",
        --         description = "Request timeout in seconds (default: 10)",
        --         type = "number",
        --         optional = true,
        --       },
        --     },
        --   },
        --   returns = {
        --     {
        --       name = "content",
        --       description = "The fetched web content",
        --       type = "string",
        --     },
        --     {
        --       name = "url",
        --       description = "The actual URL that was fetched",
        --       type = "string",
        --     },
        --     {
        --       name = "mimetype",
        --       description = "MIME type of the fetched content",
        --       type = "string",
        --       optional = true,
        --     },
        --     {
        --       name = "error",
        --       description = "Error message if the fetch was not successful",
        --       type = "string",
        --       optional = true,
        --     },
        --   },
        --   func = function(params, on_log, on_complete)
        --     local url = params.url
        --     local timeout = params.timeout or 10
        --     -- Auto-prepend https:// if no protocol specified
        --     if not url:match("^https?://") then
        --       url = "https://" .. url
        --     end
        --     on_log("Fetching content from: " .. url)
        --     local curl_cmd = string.format(
        --       "curl -s -L --max-time %d --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36' -w '\\n%%{content_type}' '%s'",
        --       timeout,
        --       url:gsub("'", "'\"'\"'") -- Escape single quotes for shell
        --     )
        --
        --     local output = vim.fn.system(curl_cmd)
        --     local exit_code = vim.v.shell_error
        --
        --     if exit_code ~= 0 then
        --       return {
        --         error = "Failed to fetch URL: " .. url .. " (exit code: " .. exit_code .. ")",
        --       }
        --     end
        --
        --     local lines = vim.split(output, "\n")
        --     local content_type = lines[#lines] -- Last line is content-type
        --     table.remove(lines) -- Remove content-type line
        --     local content = table.concat(lines, "\n")
        --
        --     if content == "" then
        --       return {
        --         error = "No content received from URL: " .. url,
        --       }
        --     end
        --
        --     on_log("Successfully fetched " .. #content .. " characters")
        --
        --     return {
        --       content = content,
        --       url = url,
        --       mimetype = content_type ~= "" and content_type or nil,
        --     }
        --   end,
        -- },
      }
    end,
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
