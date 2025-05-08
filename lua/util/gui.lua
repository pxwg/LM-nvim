local M = {}

function M.get_gui_info()
  return {
    client = {
      neovide = vim.g.neovide ~= nil,
      firenvim = vim.g.started_with_firenvim == true,
      gui_running = vim.fn.has("gui_running") == 1,
    },
    features = {
      has_gui = vim.fn.has("gui") == 1,
      font = vim.o.guifont,
    },
  }
end

return M
