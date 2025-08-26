-- Main input method manager
-- Coordinates rime_ls and dictionary_lsp based on treesitter context
-- Replaces scattered logic from lua/util/math_autochange.lua

local M = {}

local state_manager = require("core.input.state_manager")
local detector = require("core.input.treesitter_detector")
local rime_manager = require("core.input.rime_manager")
local dictionary_manager = require("core.input.dictionary_manager")

-- Auto-toggle input methods based on cursor position
local function auto_toggle_input_methods()
  -- Only process supported file types
  local filetype = vim.bo.filetype
  if not (filetype == "tex" or filetype == "plaintex" or filetype == "typst" or filetype == "markdown") then
    return
  end

  local should_disable_rime = detector.should_disable_rime()
  local currently_in_math = state_manager.is_in_math_environment()
  
  -- Entering math environment
  if should_disable_rime and not currently_in_math then
    -- Save current state and switch to math mode defaults
    state_manager.enter_math_environment()
    -- In math environment: enable dictionary, disable rime
    rime_manager.set_enabled(false)
    dictionary_manager.set_enabled(true)
    
  -- Exiting math environment  
  elseif not should_disable_rime and currently_in_math then
    -- Get original states before restoring
    local original_rime = state_manager.get_original_rime_state()
    local original_dict = state_manager.get_original_dict_state()
    
    -- Restore original states
    state_manager.exit_math_environment()
    
    -- Apply the original states to the LSP clients
    if original_rime ~= nil then
      rime_manager.set_enabled(original_rime)
    end
    if original_dict ~= nil then
      dictionary_manager.set_enabled(original_dict)
    end
  end
  -- If no state change needed (staying in same environment), do nothing
end

-- Manual toggle for rime (with keyboard shortcut)
function M.manual_toggle_rime()
  -- Toggle both rime and dictionary
  rime_manager.toggle()
  
  -- Update state to reflect manual change
  local is_toggled = state_manager.is_rime_toggled()
  state_manager.set_rime_toggled(not is_toggled)
  state_manager.set_changed_by_auto(false)
end

-- Setup autocmds for automatic switching
local function setup_autocmds()
  local autocmd = vim.api.nvim_create_autocmd
  
  -- Auto-toggle on cursor movement in insert mode
  autocmd("CursorMovedI", {
    pattern = { "*.tex", "*.typ", "*.md" },
    callback = auto_toggle_input_methods,
    desc = "Auto-toggle input methods based on treesitter context",
  })
  
  -- Also handle initial buffer enter
  autocmd("InsertEnter", {
    pattern = { "*.tex", "*.typ", "*.md" },
    callback = auto_toggle_input_methods,
    desc = "Auto-toggle input methods on insert enter",
  })
end

-- Setup keybindings
local function setup_keymaps()
  -- Global keymap for manual rime toggle (overrides individual manager keymap)
  vim.keymap.set("n", "<leader>rr", M.manual_toggle_rime, { desc = "Toggle [R]ime input method" })
  
  -- Keymap for syncing rime settings
  vim.keymap.set("n", "<leader>rs", function()
    rime_manager.sync_settings()
  end, { desc = "[R]ime [S]ync settings" })
  
  -- Debug keymap to check current context
  vim.keymap.set("n", "<leader>ri", function()
    local context = detector.get_context()
    local state = state_manager.get_state()
    vim.notify(vim.inspect({ context = context, state = state }), vim.log.levels.INFO)
  end, { desc = "[R]ime [I]nfo - debug input method state" })
end

-- Initialize the input method system
function M.setup()
  -- Initialize global variables for backward compatibility
  state_manager.init_globals()
  
  -- Setup individual managers
  rime_manager.setup()
  dictionary_manager.setup()
  
  -- Setup coordination
  setup_autocmds()
  setup_keymaps()
  
  vim.notify("Input method management system initialized", vim.log.levels.INFO)
end

-- Attach both input methods to a buffer
function M.attach_to_buffer(bufnr)
  rime_manager.attach_to_buffer(bufnr)
  dictionary_manager.attach_to_buffer(bufnr)
end

-- Expose managers for advanced usage
M.rime = rime_manager
M.dictionary = dictionary_manager
M.state = state_manager
M.detector = detector

-- Legacy compatibility functions (for gradual migration)
M.toggle_rime = M.manual_toggle_rime
M.check_rime_status = rime_manager.is_running
M.start_rime_ls = rime_manager.start_daemon

return M