-- Core module initialization
-- This module loads and configures the core components of LM-nvim

local M = {}

-- Core configuration loading order
M.setup = function()
  require("core.config").setup()     -- Basic vim options and settings  
  require("core.autocmds").setup()   -- Core autocmds
  require("core.keymaps").setup()    -- Core keymaps
  require("core.input").setup()      -- Input method management
  require("languages").setup()       -- Language-specific configurations
end

-- For backward compatibility
M.load_core = M.setup

return M