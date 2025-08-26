local M = {}

-- Legacy compatibility layer for dictionary_lsp
-- Redirects to new core.input system while preserving existing API

function M.dictionary_setup()
  -- Use new input management system (will setup both rime and dictionary)
  require("core.input").setup()
end

function M.toggle_dictionary()
  require("core.input").dictionary.toggle()
end

-- Additional compatibility functions
function M.check_dictionary_status()
  return require("core.input").dictionary.is_running()
end

function M.attach_dictionary_to_buffer(bufnr)
  require("core.input").dictionary.attach_to_buffer(bufnr)
end

return M