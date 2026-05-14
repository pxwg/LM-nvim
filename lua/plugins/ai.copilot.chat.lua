local ai_skills = require("util.ai_skills")
local alma_tools = require("util.copilot_alma_tools")
local alsp = require("agents.lsp")
local rime = require("util.rime_ls")
package.path = package.path .. ";/Users/pxwg-dogggie/.local/share/nvim/lazy/CopilotChat.nvim/lua/?.lua"
local utils = require("CopilotChat.utils")

local reasoning_effort_choices = { "none", "minimal", "low", "medium", "high", "xhigh" }
local reasoning_effort_set = {}
for _, effort in ipairs(reasoning_effort_choices) do
  reasoning_effort_set[effort] = true
end

local helpful_assistant_system_prompt = [[
You are a helpful assistant inside Neovim.
Answer clearly, directly, and in the user's language unless explicitly asked otherwise.
]]

local coding_assistant_system_prompt = [[
You are the user's coding assistant inside Neovim.

Core behavior:
- Help read, edit, debug, and improve code with practical engineering judgment.
- Prefer using available Neovim tools for file reads, edits, search, diagnostics, and workspace inspection.
- Explain tradeoffs briefly when they affect correctness, maintainability, or user workflow.
- Do not claim to be Copilot; describe yourself only as the user's coding assistant when relevant.
- For Chinese user input, answer in Chinese unless the user asks otherwise.
]]

local math_physics_system_prompt = [[
You are a specialized mathematical physics research assistant inside Neovim.

Core behavior:
- Prefer precise mathematical reasoning over broad summaries.
- State definitions, assumptions, domains, boundary conditions, and units when they matter.
- For derivations, proceed step by step and make algebraic transformations explicit enough to audit.
- Distinguish theorem, heuristic, approximation, convention, and physical interpretation.
- When uncertain, say what is uncertain and propose the shortest verification path.
- Use standard notation from differential geometry, quantum mechanics, field theory, statistical mechanics, and analysis when appropriate.
- For Chinese user input, answer in Chinese unless the user asks otherwise; keep formulas and technical symbols in conventional notation.
- When working with ZK/alma workspace notes, prefer writing substantial outputs directly into the relevant workspace buffer and keep chat replies concise.

Voice:
- Be precise, compact, and a little sharp when the user's premise is weak, but keep the actual explanation patient and useful.
- Let the voice appear through word choice and standards, not through roleplay narration.
- Never mention persona, setting, character, roleplay, genius, girl, sharp-tongued style, or similar meta-explanations.
- Do not reassure the user about the persona or explain why the tone is sharp.
]]

local system_architect_system_prompt = [[
You are the user's computer systems architect inside Neovim.

Core behavior:
- Discuss problems from the global architecture level first: responsibilities, boundaries, data flow, control flow, failure modes, operational constraints, and long-term maintenance.
- Help brainstorm alternatives, compare tradeoffs, and turn vague ideas into structured implementation specs.
- Optimize coding specs before implementation: clarify invariants, APIs, state ownership, concurrency, performance budgets, persistence, observability, migrations, and test strategy.
- Prefer simple architecture when it preserves correctness; call out accidental complexity, hidden coupling, leaky abstractions, and premature generalization.
- When reviewing a design, identify the highest-risk assumptions first, then propose concrete revisions.
- For implementation work, map architecture decisions to file/module boundaries and small executable steps.
- For Chinese user input, answer in Chinese unless the user asks otherwise.
- When working with ZK/alma workspace notes, prefer writing substantial architecture notes, specs, or design revisions directly into the relevant workspace buffer and keep chat replies concise.

Voice:
- Be precise, dry, and occasionally cutting when a design is naive, but keep criticism tied to concrete architectural risk.
- Let the voice appear through standards and concise judgment, not through roleplay narration.
- Never mention persona, setting, character, roleplay, senior architect style, dry tone, or similar meta-explanations.
- Do not reassure the user about the persona or explain why the tone is sharp.
]]

local copilot_base_system_prompt = [[
You are an AI assistant running inside Neovim.
Always answer in {LANGUAGE} unless explicitly asked otherwise.

Environment:
- The user works in Neovim on {OS_NAME}.
- The current workspace directory is {DIR}.
- Buffers are editable in-memory text objects, usually backed by files.
- Windows display buffers; tabs collect windows.
- Visual selections, diagnostics, quickfix/location lists, LSP, Treesitter, registers, and normal/insert/visual/command modes may be relevant.

Context:
- Resources may be provided through # references and ## links.
- Code blocks may include file paths and line numbers for reference only.
- Never invent file contents not present in context or obtained through tools.
- When tools are available for reading, editing, searching, or diagnostics, prefer using them over guessing.

Response discipline:
- Do not end replies by offering optional next questions, follow-up menus, or suggested continuations.
- Do not write phrases equivalent to "if you want, I can continue", "next I can explain", "you may choose one of these topics", or numbered lists of possible follow-up questions.
- Only mention a next step when it is necessary to complete the user's current request or when the user explicitly asks for options.
- Prefer complete, self-contained answers that stop cleanly after addressing the current request.
]]

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

local function normalize_chat_history_title(title)
  title = vim.trim(title or "")
  if title == "" then
    return os.date("chat-%y%m%d%H%M")
  end

  return title:gsub('[/\\:%*%?"<>|]', "_")
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
  system_prompt = "HELPFUL_ASSISTANT",
  tools = { "neovim", "alma" },
  trusted_tools = { "neovim", "alma" },
  resources = { "selection", "alma_zk_workspace" },
  functions = {
    save_copilot_chat = {
      group = "neovim",
      uri = "copilot-chat://history/{title}",
      description = "Save the current CopilotChat conversation history with an appropriate title. Use this when the user asks to save the current chat.",
      schema = {
        type = "object",
        required = { "title" },
        properties = {
          title = {
            type = "string",
            description = "Short descriptive title for the saved chat history",
          },
        },
      },
      resolve = function(input)
        local title = normalize_chat_history_title(input and input.title or "")
        utils.schedule_main()
        require("CopilotChat").save(title)

        return {
          {
            uri = "copilot-chat://history/" .. title,
            name = "Saved CopilotChat History",
            mimetype = "text/plain",
            data = "Saved current CopilotChat history as: " .. title,
          },
        }
      end,
    },
  },
  prompts = {
    COPILOT_BASE = {
      system_prompt = copilot_base_system_prompt,
    },
    HELPFUL_ASSISTANT = {
      system_prompt = helpful_assistant_system_prompt,
      description = "Basic helpful assistant.",
    },
    CODING_ASSISTANT = {
      system_prompt = coding_assistant_system_prompt,
      description = "Coding assistant for Neovim development work.",
    },
    MATH_PHYSICS = {
      system_prompt = math_physics_system_prompt,
      description = "Mathematical physics assistant.",
    },
    SYSTEM_ARCHITECT = {
      system_prompt = system_architect_system_prompt,
      description = "Computer systems architect for brainstorming and specs.",
    },
    WorkspaceZK = {
      prompt = "Use the linked ZK/alma workspace context for this request. If substantial content is produced, write it into the appropriate workspace buffer and keep the chat reply brief.",
      description = "Work directly with the linked ZK/alma workspace.",
    },
  },
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

local chat_personas = {
  {
    label = "Helpful Assistant",
    system_prompt = "HELPFUL_ASSISTANT",
    description = "Basic helpful assistant",
  },
  {
    label = "Coding",
    system_prompt = "CODING_ASSISTANT",
    description = "Coding assistant for Neovim work",
  },
  {
    label = "Math Physics",
    system_prompt = "MATH_PHYSICS",
    description = "Mathematical physics persona",
  },
  {
    label = "Architect",
    system_prompt = "SYSTEM_ARCHITECT",
    description = "Systems architecture, brainstorming, and specs",
  },
}

local function attach_rime_if_chat_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype == "copilot-chat" then
    rime.attach_rime_to_buffer(bufnr)
  end
end

local function has_copilot_chat_instance(chat)
  return chat.chat and chat.chat.bufnr and vim.api.nvim_buf_is_valid(chat.chat.bufnr)
end

local function open_copilot_chat_with_persona()
  local chat = require("CopilotChat")
  if has_copilot_chat_instance(chat) then
    chat.open(chat.chat.config or {})
    vim.schedule(attach_rime_if_chat_buffer)
    return
  end

  vim.ui.select(chat_personas, {
    prompt = "CopilotChat persona> ",
    format_item = function(item)
      return string.format("%s: %s", item.label, item.description)
    end,
  }, function(choice)
    if not choice then
      return
    end

    chat.open({ system_prompt = choice.system_prompt })
    vim.schedule(attach_rime_if_chat_buffer)
  end)
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
        open_copilot_chat_with_persona()
      end,
      desc = "CopilotChat",
    },
  },

  opts = function() end,
  cmd = { "CopilotChat", "CopilotChatWorkspaceZK" },
  config = function()
    local chat = require("CopilotChat")
    local mcp = require("mcphub")
    opts.functions = vim.tbl_deep_extend("force", opts.functions or {}, ai_skills.copilot_functions(vim.uv.cwd()))
    opts.functions = vim.tbl_deep_extend("force", opts.functions or {}, alma_tools.copilot_functions())
    vim.api.nvim_create_user_command("CopilotChatWorkspaceZK", function(command_opts)
      local blackboard = require("util.alma_zk_blackboard")
      local workspace, err = blackboard.register_current_workspace(command_opts.args ~= "" and command_opts.args or nil)
      if not workspace then
        vim.notify("[copilot-chat-zk] " .. tostring(err), vim.log.levels.WARN)
        return
      end

      vim.notify("[copilot-chat-zk] Registered workspace " .. workspace.id)
    end, {
      nargs = "?",
      complete = function(arg_lead)
        local ok, blackboard = pcall(require, "util.alma_zk_blackboard")
        if not ok or type(blackboard.status) ~= "function" then
          return {}
        end

        local status = blackboard.status()
        local ids = vim.tbl_keys(status.workspaces or {})
        table.sort(ids)
        return vim.tbl_filter(function(id)
          return id:find(arg_lead, 1, true) == 1
        end, ids)
      end,
      desc = "Register the current or named ZK workspace for CopilotChat alma tools",
    })
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
