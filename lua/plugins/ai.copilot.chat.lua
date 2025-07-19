local alsp = require("agents.lsp")
local rime = require("util.rime_ls")

local function input_lsp(callback, source)
  return alsp.input_lsp(callback, source)
end

local function resolve_lsp(init_func, input, source)
  return alsp.resolve_lsp(init_func, input, source)
end

return {
  -- "CopilotC-Nvim/CopilotChat.nvim",
  "deathbeam/CopilotChat.nvim",
  branch = "tools",
  enabled = vim.g.copilot_chat_enabled or false,
  dependencies = {
    { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
    { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    { "ravitemer/mcphub.nvim" },
  },
  build = "make tiktoken", -- Only on MacOS or Linux

  keys = {
    -- {
    --   "<leader>aa",
    --   function()
    --     vim.cmd("CopilotChatToggle")
    --     vim.cmd("LspStart rime_ls")
    --     -- vim.cmd(":vert wincmd L")
    --   end,
    --   desc = "CopilotChat",
    -- },
    {
      "<C-c>",
      function()
        -- HACK: Attach rime and dictionary manually
        vim.cmd("CopilotChatToggle")
        local bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype == "copilot-chat" then
          rime.attach_rime_to_buffer(bufnr)
        end
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CopilotChat",
    },
  },

  opts = function()
    local utils = require("CopilotChat.utils")
    return {
      chat_autocomplete = false,
      mappings = {
        show_diff = {
          full_diff = true,
        },
      },
      contexts = {
        neovim = {
          description = "Executes Neovim command and returns the output. Format: <command>",
          input = function(callback, source)
            vim.ui.input({
              prompt = "Enter Neovim command> ",
            }, callback)
          end,
          resolve = function(input, source)
            if not input or input == "" then
              return {}
            end
            utils.schedule_main()

            -- Use execute() to capture output instead of redir
            local output = ""
            local success, result = pcall(function()
              return vim.api.nvim_exec2(input, { output = true })
            end)

            if success then
              output = result.output
            else
              output = "Error executing command: " .. tostring(result)
            end

            -- If output is empty, try to provide some feedback
            if output == "" then
              if success then
                output = "Command executed successfully with no output."
              else
                output = "Command failed with no output."
              end
            end
            return {
              {
                content = "Command: " .. input .. "\n\n" .. output,
                filename = "neovim_command_output",
                filetype = "text",
                score = 1.0, -- High relevance
              },
            }
          end,
        },
        function_doc = {
          description = "Gets precise function document with LSP. Format: [filepath:]function_name",
          input = function(callback, source)
            return input_lsp(callback, source)
          end,
          resolve = function(input, source)
            return resolve_lsp(utils.schedule_main(), input, source)
          end,
        },
      },

      auto_insert_mode = false, -- Automatically enter insert mode when opening window and on new prompt
      debug = false, -- Enable debugging
      reset = {
        normal = "<C-b>",
        insert = "<C-b>",
      },
      -- prompts = {
      --   nvim_runner = {
      --     system_prompt = USER_SYSTEM_PROMPT,
      --   },
      -- },
      complete = {
        detail = "Use @<localleader>s or /<localleader>s for options.",
        insert = "<localleader>s",
      },
      question_header = "󰩃  Doggie  ",
      answer_header = "⚡ Copilot ",
      -- model = "claude-sonnet-4", -- Set claude model as default
      window = {
        layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
        width = 0.3, -- fractional width of parent, or absolute width in columns when > 1
      },
    }
  end,
  cmd = "CopilotChat",
  config = function(_, opts)
    local chat = require("CopilotChat")
    local mcp = require("mcphub")
    mcp.setup()
    mcp.on({ "servers_updated", "tool_list_changed", "resource_list_changed" }, function()
      local hub = mcp.get_hub_instance()
      if not hub then
        return
      end

      local async = require("plenary.async")
      local call_tool = async.wrap(function(server, tool, input, callback)
        hub:call_tool(server, tool, input, {
          callback = function(res, err)
            callback(res, err)
          end,
        })
      end, 4)

      local access_resource = async.wrap(function(server, uri, callback)
        hub:access_resource(server, uri, {
          callback = function(res, err)
            callback(res, err)
          end,
        })
      end, 3)

      local resources = hub:get_resources()
      for _, resource in ipairs(resources) do
        local name = resource.name:lower():gsub(" ", "_"):gsub(":", "")
        chat.config.functions[name] = {
          uri = resource.uri,
          description = type(resource.description) == "string" and resource.description or "",
          resolve = function()
            local res, err = access_resource(resource.server_name, resource.uri)
            if err then
              error(err)
            end

            res = res or {}
            local result = res.result or {}
            local content = result.contents or {}
            local out = {}

            for _, message in ipairs(content) do
              if message.text then
                table.insert(out, {
                  uri = message.uri,
                  data = message.text,
                  mimetype = message.mimeType,
                })
              end
            end

            return out
          end,
        }
      end

      local tools = hub:get_tools()
      for _, tool in ipairs(tools) do
        chat.config.functions[tool.name] = {
          group = tool.server_name,
          description = tool.description,
          schema = tool.inputSchema,
          resolve = function(input)
            local res, err = call_tool(tool.server_name, tool.name, input)
            if err then
              error(err)
            end

            res = res or {}
            local result = res.result or {}
            local content = result.content or {}
            local out = {}

            for _, message in ipairs(content) do
              if message.type == "text" then
                table.insert(out, {
                  data = message.text,
                })
              elseif message.type == "resource" and message.resource and message.resource.text then
                table.insert(out, {
                  uri = message.resource.uri,
                  data = message.resource.text,
                  mimetype = message.resource.mimeType,
                })
              end
            end

            return out
          end,
        }
      end
    end)
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
