-- Dictionary LSP manager for English input method
-- Consolidates dictionary_lsp management logic

local M = {}

local state_manager = require("core.input.state_manager")

-- Initialize dictionary LSP client
function M.setup_lsp()
  local lspconfig = require("lspconfig")
  local configs = require("lspconfig.configs")

  -- Initialize dictionary state
  state_manager.set_dict_enabled(false)

  -- Register the dictionary LSP server
  if not configs.dictionary then
    configs.dictionary = {
      default_config = {
        cmd = { vim.fn.expand("~/dictionary_lsp/target/release/dictionary_lsp") },
        autostart = true,
        single_file_support = true,
        root_dir = function(fname)
          return vim.fs.dirname(fname) or vim.fn.getcwd()
        end,
      },
    }
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.general.positionEncodings = { "utf-8" }

  lspconfig.dictionary.setup({
    single_file_support = true,
    capabilities = capabilities,
  })
end

-- Toggle dictionary on/off
function M.toggle()
  local client = vim.lsp.get_clients({ name = "dictionary" })[1]
  if client then
    client.request("workspace/executeCommand", { command = "dictionary.toggle-cmp" }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        state_manager.set_dict_enabled(result)
      end
    end)
  end
end

-- Check if dictionary client is attached to current buffer
function M.is_attached()
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, client in ipairs(clients) do
    if client.name == "dictionary" then
      return true
    end
  end
  return false
end

-- Check if dictionary client is running
function M.is_running()
  local clients = vim.lsp.get_clients({ name = "dictionary" })
  return #clients > 0
end

-- Attach dictionary client to specific buffer
function M.attach_to_buffer(bufnr)
  local active_clients = vim.lsp.get_clients()
  local dict_client_id = nil

  for _, client in ipairs(active_clients) do
    if client.name == "dictionary" then
      dict_client_id = client.id
      break
    end
  end

  if dict_client_id then
    vim.lsp.buf_attach_client(bufnr, dict_client_id)
  else
    vim.notify("dictionary client not found", vim.log.levels.ERROR)
  end
end

-- Force enable/disable dictionary
-- Since dictionary LSP only has toggle-cmp command, we need to track state
function M.set_enabled(enabled)
  local client = vim.lsp.get_clients({ name = "dictionary" })[1]
  if client then
    local current_state = state_manager.is_dict_enabled()

    -- Only toggle if the current state differs from desired state
    if current_state ~= enabled then
      client.request("workspace/executeCommand", { command = "dictionary.toggle-cmp" }, function(_, result, ctx, _)
        if ctx.client_id == client.id then
          state_manager.set_dict_enabled(result)
        end
      end)
    end
  end
end

-- Initialize dictionary system
function M.setup()
  M.setup_lsp()
end

return M
