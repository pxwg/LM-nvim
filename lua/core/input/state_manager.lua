-- Centralized state management for input methods
-- Replaces scattered global variables with a proper state manager

local M = {}

-- Internal state
local state = {
  rime_enabled = true,
  rime_toggled = true,
  rime_ls_active = true,
  rime_math = false,
  dict_enabled = false,
  changed_by_auto = false, -- renamed from changed_by_this for clarity
  -- Original state tracking for math environment switching
  original_rime_enabled = nil,
  original_dict_enabled = nil,
  in_math_environment = false,
}

-- State getters
function M.is_rime_enabled()
  return vim.g.rime_enabled or state.rime_enabled
end

function M.is_rime_toggled()
  return state.rime_toggled
end

function M.is_rime_active()
  return state.rime_ls_active
end

function M.is_rime_math_mode()
  return state.rime_math
end

function M.is_dict_enabled()
  return vim.g.dict_enabled or state.dict_enabled
end

function M.is_changed_by_auto()
  return state.changed_by_auto
end

function M.is_in_math_environment()
  return state.in_math_environment
end

function M.get_original_rime_state()
  return state.original_rime_enabled
end

function M.get_original_dict_state()
  return state.original_dict_enabled
end

-- Initialize global variables for backward compatibility
-- These were previously set in math_autochange.lua
function M.init_globals()
  _G.rime_toggled = state.rime_toggled
  _G.rime_ls_active = state.rime_ls_active
  _G.rime_math = state.rime_math
  _G.changed_by_this = state.changed_by_auto
end

-- Sync state with global variables
function M.sync_globals()
  _G.rime_toggled = state.rime_toggled
  _G.rime_ls_active = state.rime_ls_active
  _G.rime_math = state.rime_math
  _G.changed_by_this = state.changed_by_auto
end

-- State setters
function M.set_rime_enabled(enabled)
  vim.g.rime_enabled = enabled
  state.rime_enabled = enabled
end

function M.set_rime_toggled(toggled)
  state.rime_toggled = toggled
  _G.rime_toggled = toggled
end

function M.set_rime_active(active)
  state.rime_ls_active = active
  _G.rime_ls_active = active
end

function M.set_rime_math_mode(math_mode)
  state.rime_math = math_mode
  _G.rime_math = math_mode
end

function M.set_dict_enabled(enabled)
  vim.g.dict_enabled = enabled
  state.dict_enabled = enabled
end

function M.set_changed_by_auto(changed)
  state.changed_by_auto = changed
  _G.changed_by_this = changed
end

function M.set_in_math_environment(in_math)
  state.in_math_environment = in_math
end

-- Save current state as original state (before entering math environment)
function M.save_original_state()
  state.original_rime_enabled = M.is_rime_enabled()
  state.original_dict_enabled = M.is_dict_enabled()
end

-- Restore original state (when exiting math environment)
function M.restore_original_state()
  if state.original_rime_enabled ~= nil and state.original_dict_enabled ~= nil then
    M.set_rime_enabled(state.original_rime_enabled)
    M.set_dict_enabled(state.original_dict_enabled)
    -- Clear original state after restoration
    state.original_rime_enabled = nil
    state.original_dict_enabled = nil
  end
end

-- Combined state operations
function M.enter_math_environment()
  -- Save current state before switching
  M.save_original_state()
  M.set_in_math_environment(true)
  M.set_rime_math_mode(true)
  M.set_changed_by_auto(true)
end

function M.exit_math_environment()
  -- Restore original state
  M.restore_original_state()
  M.set_in_math_environment(false)
  M.set_rime_math_mode(false)
  M.set_changed_by_auto(false)
end

-- Legacy functions for backward compatibility
function M.disable_rime_for_math()
  M.enter_math_environment()
end

function M.enable_rime_for_text()
  M.exit_math_environment()
end

function M.reset_state()
  state.rime_enabled = true
  state.rime_toggled = true
  state.rime_ls_active = true
  state.rime_math = false
  state.dict_enabled = false
  state.changed_by_auto = false
  state.original_rime_enabled = nil
  state.original_dict_enabled = nil
  state.in_math_environment = false
end

-- Debug function to view current state
function M.get_state()
  return {
    rime_enabled = M.is_rime_enabled(),
    rime_toggled = M.is_rime_toggled(),
    rime_ls_active = M.is_rime_active(),
    rime_math = M.is_rime_math_mode(),
    dict_enabled = M.is_dict_enabled(),
    changed_by_auto = M.is_changed_by_auto(),
    in_math_environment = M.is_in_math_environment(),
    original_rime_state = M.get_original_rime_state(),
    original_dict_state = M.get_original_dict_state(),
  }
end

return M