local alsp = require("agents.lsp")
local ai_skills = require("util.ai_skills")
local rime = require("util.rime_ls")
package.path = package.path .. ";/Users/pxwg-dogggie/.local/share/nvim/lazy/CopilotChat.nvim/lua/?.lua"

local reasoning_effort_choices = { "none", "minimal", "low", "medium", "high", "xhigh" }
local reasoning_effort_set = {}
for _, effort in ipairs(reasoning_effort_choices) do
  reasoning_effort_set[effort] = true
end

local function model_supports_reasoning_effort(model_id)
  return model_id:match("^gpt%-5") ~= nil or model_id:match("^gpt%-oss") ~= nil or model_id:match("^o%d") ~= nil
end

local function split_reasoning_model_id(model_id)
  local base_model, effort = model_id:match("^(.*)%-([^%-]+)$")
  if base_model and reasoning_effort_set[effort] then
    return base_model, effort
  end

  return model_id, nil
end

local function local_openai_model_entry(model_id)
  return {
    id = model_id,
    name = model_id,
    tokenizer = "o200k_base",
    streaming = true,
    tools = true,
  }
end

local function expand_local_openai_model(model_id)
  if not model_supports_reasoning_effort(model_id) then
    return { local_openai_model_entry(model_id) }
  end

  return vim
    .iter(reasoning_effort_choices)
    :map(function(effort)
      return local_openai_model_entry(model_id .. "-" .. effort)
    end)
    :totable()
end

local function get_local_openai_model_entries()
  local ok, curl = pcall(require, "CopilotChat.utils.curl")
  if not ok then
    return expand_local_openai_model("gpt-5.5")
  end

  local response, err = curl.get("http://localhost:8080/v1/models", {
    json_response = true,
    headers = {
      ["Authorization"] = "pwd",
      ["Content-Type"] = "application/json",
    },
  })

  if
    err
    or not response
    or response.status ~= 200
    or type(response.body) ~= "table"
    or type(response.body.data) ~= "table"
  then
    return expand_local_openai_model("gpt-5.5")
  end

  local models = {}
  for _, model in ipairs(response.body.data) do
    if type(model) == "table" and type(model.id) == "string" then
      vim.list_extend(models, expand_local_openai_model(model.id))
    end
  end

  return models
end

local opts = {
  chat_autocomplete = false,
  tools = { "@neovim", "@copilot" },
  providers = {
    copilot = {
      disabled = true,
    },
    openai = {
      get_headers = function()
        return {
          ["Authorization"] = "pwd",
          ["Content-Type"] = "application/json",
        }
      end,
      get_models = function()
        return get_local_openai_model_entries()
      end,
      prepare_input = function(inputs, provider_opts)
        local base_model, reasoning_effort = split_reasoning_model_id(provider_opts.model.id)
        local request_opts = vim.deepcopy(provider_opts)
        request_opts.model.id = base_model

        local input = require("CopilotChat.config.providers").copilot.prepare_input(inputs, request_opts)
        if reasoning_effort then
          input.reasoning_effort = reasoning_effort
        end
        return input
      end,
      prepare_output = function(output, provider_opts)
        return require("CopilotChat.config.providers").copilot.prepare_output(output, provider_opts)
      end,
      get_url = function()
        return "http://localhost:8080/v1/chat/completions"
      end,
    },
  },
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
  model = "gpt-5.5-medium",
  window = {
    layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
    width = 0.3, -- fractional width of parent, or absolute width in columns when > 1
  },
  separator = "━",
  headers = {
    user = "💫 pxwg",
    assistant = "✨ Ai",
    tool = "🔭 Tool",
  },
}

local function input_lsp(callback, source)
  return alsp.input_lsp(callback, source)
end

local function resolve_lsp(init_func, input, source)
  return alsp.resolve_lsp(init_func, input, source)
end

return {
  -- "CopilotC-Nvim/CopilotChat.nvim",
  "deathbeam/CopilotChat.nvim",
  enabled = vim.g.copilot_chat_enabled or false,
  dependencies = {
    -- { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
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

  opts = function() end,
  cmd = "CopilotChat",
  config = function()
    local chat = require("CopilotChat")
    local mcp = require("mcphub")
    opts.functions = vim.tbl_deep_extend("force", opts.functions or {}, ai_skills.copilot_functions(vim.uv.cwd()))
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
