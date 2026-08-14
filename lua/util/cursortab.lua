local M = {}

local partial_accept_callback

local function notify_error(action, err)
  vim.schedule(function()
    vim.notify_once(string.format("CursorTab %s failed: %s", action, err), vim.log.levels.ERROR)
  end)
end

function M.register_partial_accept(lhs)
  local mapping = vim.fn.maparg(lhs, "i", false, true)
  if type(mapping) ~= "table" or type(mapping.callback) ~= "function" then
    error(string.format("CursorTab partial-accept mapping was not registered for %s", lhs))
  end
  partial_accept_callback = mapping.callback
end

function M.accept()
  local ok_require, cursortab = pcall(require, "cursortab")
  if not ok_require then
    return false
  end

  local ok_accept, accepted = pcall(cursortab.accept)
  if not ok_accept then
    notify_error("accept", accepted)
    return false
  end
  return accepted == true
end

function M.partial_accept()
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode ~= "i" and mode ~= "n" then
    return false
  end
  if type(partial_accept_callback) ~= "function" then
    return false
  end

  local ok_accept, fallback = pcall(partial_accept_callback)
  if not ok_accept then
    notify_error("partial accept", fallback)
    return false
  end

  return fallback == ""
end

return M
