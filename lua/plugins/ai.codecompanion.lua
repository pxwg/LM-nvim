local function get_local_openai_models()
  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    return { "gpt-5.5" }
  end

  local ok_response, response = pcall(function()
    return curl.get("http://localhost:8080/v1/models", {
      sync = true,
      headers = {
        ["Content-Type"] = "application/json",
        Authorization = "pwd",
      },
    })
  end)
  if not ok_response or not response or response.status ~= 200 then
    return { "gpt-5.5" }
  end

  local ok_json, json = pcall(vim.json.decode, response.body)
  if not ok_json or type(json) ~= "table" or type(json.data) ~= "table" then
    return { "gpt-5.5" }
  end

  local models = {}
  for _, model in ipairs(json.data) do
    if type(model) == "table" and type(model.id) == "string" then
      table.insert(models, model.id)
    end
  end

  return #models > 0 and models or { "gpt-5.5" }
end

local reasoning_effort_choices = { "none", "minimal", "low", "medium", "high", "xhigh" }
local reasoning_effort_set = {}
for _, effort in ipairs(reasoning_effort_choices) do
  reasoning_effort_set[effort] = true
end

local function get_local_openai_reasoning_effort()
  local effort = vim.g.openai_reasoning_effort or "medium"
  return reasoning_effort_set[effort] and effort or "medium"
end

return {
  "olimorris/codecompanion.nvim",
  enabled = vim.g.codecompanion_enabled or false,
  event = "VeryLazy",
  dependencies = {
    "ravitemer/mcphub.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  keys = {
    {
      "<C-c>",
      function()
        vim.cmd("CodeCompanionChat")
        vim.cmd("LspStart rime_ls")
        -- vim.cmd(":vert wincmd L")
      end,
      desc = "CodeCompanionChat",
    },
  },
  opts = {
    adapters = {
      openai = function()
        return require("codecompanion.adapters").extend("openai_compatible", {
          env = {
            api_key = "pwd",
            url = "http://localhost:8080",
            chat_url = "/v1/chat/completions",
          },
          headers = {
            ["Content-Type"] = "application/json",
            Authorization = "${api_key}",
          },
          schema = {
            model = {
              default = "gpt-5.5",
              choices = get_local_openai_models,
            },
            reasoning_effort = {
              order = 2,
              mapping = "parameters",
              type = "enum",
              desc = "Constrains effort on reasoning for reasoning models.",
              default = get_local_openai_reasoning_effort,
              choices = reasoning_effort_choices,
            },
          },
        })
      end,
    },
    extensions = {
      -- mcphub = {
      --   callback = "mcphub.extensions.codecompanion",
      --   opts = {
      --     show_result_in_chat = true, -- Show mcp tool results in chat
      --     make_vars = true, -- Convert resources to #variables
      --     make_slash_commands = true, -- Add prompts as /slash commands
      --   },
      -- },
    },
    strategies = {
      chat = {
        adapter = "openai",
        model = "gpt-5.5",
      },
    },
  },
}
