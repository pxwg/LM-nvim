local M = {}

-- Legacy compatibility layer for rime_ls
-- Redirects to new core.input system while preserving existing API

function M.setup_rime()
  -- Use new input management system
  require("core.input").setup()
end

function M.toggle_rime()
  require("core.input").manual_toggle_rime()
end

function M.sync_settings()
  require("core.input").rime.sync_settings()
end

function M.start_rime_ls()
  return require("core.input").rime.start_daemon()
end

-- Preserve any other functions for backward compatibility
function M.check_rime_status()
  return require("core.input").rime.is_running()
end

function M.attach_rime_to_buffer(bufnr)
  require("core.input").attach_to_buffer(bufnr)
end

return M