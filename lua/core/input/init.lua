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
  local is_rime_active = state_manager.is_rime_active()
  local is_rime_toggled = state_manager.is_rime_toggled()
  
  -- If we should disable rime (in math/formula environment)
  if should_disable_rime and is_rime_active then
    if is_rime_toggled then
      -- Disable rime, enable dictionary
      rime_manager.set_enabled(false)
      dictionary_manager.set_enabled(true)
      state_manager.disable_rime_for_math()
    end
  -- If we should enable rime (in text environment)  
  elseif not should_disable_rime and is_rime_active then
    -- Only re-enable if it was disabled by auto-switching (not manual toggle)
    if not is_rime_toggled and (state_manager.is_changed_by_auto() or state_manager.is_rime_math_mode()) then
      -- Enable rime, disable dictionary
      rime_manager.set_enabled(true)
      dictionary_manager.set_enabled(false)
      state_manager.enable_rime_for_text()
    end
  end
  -- If rime is not active (manually disabled), do nothing
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