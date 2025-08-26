-- Rime input method manager
-- Consolidates rime_ls management logic from multiple files

local M = {}

local state_manager = require("core.input.state_manager")

-- Supported file types for rime_ls
M.FILETYPES = { "vimwiki", "tex", "markdown", "copilot-chat", "Avante", "codecompanion", "typst" }

-- Initialize rime_ls LSP client
function M.setup_lsp()
  -- Add rime-ls to lspconfig as a custom server
  local lspconfig = require("lspconfig")
  local configs = require("lspconfig.configs")
  
  if not configs.rime_ls then
    configs.rime_ls = {
      default_config = {
        name = "rime_ls",
        handlers = {
          ["window/logMessage"] = function(_, result, ctx, config)
            -- Filter out ALL messages from rime_ls regardless of level
            return
          end,
          ["window/showMessage"] = function(_, result, ctx, config)
            -- Also filter out showMessage notifications
            return
          end,
        },
        cmd = vim.lsp.rpc.connect("127.0.0.1", 9257),
        filetypes = M.FILETYPES,
        single_file_support = true,
        autostart = true,
      },
      settings = {},
      docs = {
        description = [[
https://www.github.com/wlh320/rime-ls

A language server for librime
]],
      },
    }
  end

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.general.positionEncodings = { "utf-8" }

  lspconfig.rime_ls.setup({
    init_options = {
      enabled = state_manager.is_rime_enabled(),
      shared_data_dir = "/Library/Input Methods/Squirrel.app/Contents/SharedSupport",
      user_data_dir = "~/Library/Rime_2/",
      log_dir = vim.fn.expand("~/.local/share/rime-ls-1/"),
      paging_characters = { ",", "." },
      trigger_characters = {},
      schema_trigger_character = "&",
      always_incomplete = false,
      preselect_first = false,
      show_filter_text_in_label = false,
      max_candidates = 9,
      max_tokens = 0,
      long_filter_text = true,
    },
    on_attach = M.on_attach,
    capabilities = capabilities,
  })
end

-- LSP client attach handler
function M.on_attach(client, bufnr)
  -- Set up keymaps for rime control
  vim.keymap.set("n", "<leader>rr", function()
    M.toggle()
  end, { desc = "Toggle [R]ime", buffer = bufnr })
  
  vim.keymap.set("n", "<leader>rs", function()
    M.sync_settings()
  end, { desc = "[R]ime [S]ync", buffer = bufnr })
end

-- Toggle rime on/off
function M.toggle()
  local client = vim.lsp.get_clients({ name = "rime_ls" })[1]
  if client then
    client.request("workspace/executeCommand", { command = "rime-ls.toggle-rime" }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        state_manager.set_rime_enabled(result)
        -- Also toggle dictionary when rime is toggled manually
        require("core.input.dictionary_manager").toggle()
      end
    end)
  end
end

-- Sync rime settings
function M.sync_settings()
  local client = vim.lsp.get_clients({ name = "rime_ls" })[1]
  if client then
    client.request("workspace/executeCommand", { command = "rime-ls.sync-user-data" }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        vim.notify("Rime settings synced", vim.log.levels.INFO)
      end
    end)
  end
end

-- Start rime_ls daemon process
function M.start_daemon()
  local job_id = vim.fn.jobstart(vim.fn.expand("~/rime-ls/target/release/rime_ls") .. " --listen", {
    on_stdout = function() end,
    on_stderr = function() end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.api.nvim_err_writeln("rime_ls exited with code " .. code)
      end
    end,
  })

  -- Create an autocommand to stop the job when Neovim exits
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      vim.fn.jobstop(job_id)
    end,
  })
  
  return job_id
end

-- Check if rime_ls client is attached to current buffer
function M.is_attached()
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  for _, client in ipairs(clients) do
    if client.name == "rime_ls" then
      return true
    end
  end
  return false
end

-- Check if rime_ls client is running
function M.is_running()
  local clients = vim.lsp.get_clients({ name = "rime_ls" })
  return #clients > 0
end

-- Attach rime_ls client to specific buffer
function M.attach_to_buffer(bufnr)
  local active_clients = vim.lsp.get_clients()
  local rime_client_id = nil
  
  for _, client in ipairs(active_clients) do
    if client.name == "rime_ls" then
      rime_client_id = client.id
      break
    end
  end

  if rime_client_id then
    vim.lsp.buf_attach_client(bufnr, rime_client_id)
  else
    vim.notify("rime_ls client not found", vim.log.levels.ERROR)
  end
end

-- Force enable/disable rime without toggling dictionary
function M.set_enabled(enabled)
  local client = vim.lsp.get_clients({ name = "rime_ls" })[1]
  if client then
    local command = enabled and "rime-ls.enable" or "rime-ls.disable"
    client.request("workspace/executeCommand", { command = command }, function(_, result, ctx, _)
      if ctx.client_id == client.id then
        state_manager.set_rime_enabled(enabled)
      end
    end)
  end
end

-- Initialize rime system
function M.setup()
  -- Initialize state
  state_manager.set_rime_enabled(true)
  
  -- Start daemon
  M.start_daemon()
  
  -- Setup LSP
  M.setup_lsp()
end

return M