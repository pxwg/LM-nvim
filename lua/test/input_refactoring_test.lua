-- Test script for input method refactoring
-- Validates that the new core.input system loads correctly

local M = {}

function M.test_input_system()
  local success, err = pcall(function()
    -- Test loading all modules
    local state_manager = require("core.input.state_manager")
    local detector = require("core.input.treesitter_detector")
    local rime_manager = require("core.input.rime_manager")
    local dictionary_manager = require("core.input.dictionary_manager")
    local input_main = require("core.input")
    
    print("✓ All core.input modules loaded successfully")
    
    -- Test state management
    state_manager.set_rime_enabled(true)
    assert(state_manager.is_rime_enabled() == true, "State management failed")
    print("✓ State management working")
    
    -- Test compatibility layers
    local rime_compat = require("lsp.rime_ls")
    local dict_compat = require("lsp.dictionary")
    local util_compat = require("util.rime_ls")
    print("✓ Compatibility layers loaded")
    
    -- Test main functionality exists
    assert(type(input_main.setup) == "function", "Main setup function missing")
    assert(type(input_main.manual_toggle_rime) == "function", "Manual toggle function missing")
    print("✓ Main API functions available")
    
    print("✓ All tests passed!")
    return true
  end)
  
  if not success then
    print("✗ Test failed: " .. tostring(err))
    return false
  end
  
  return true
end

function M.test_detector()
  local detector = require("core.input.treesitter_detector")
  
  -- Test environment detection functions exist
  local functions = {
    "in_text_mode", "in_math_zone", "in_tikz", "in_latex_command_brackets",
    "should_disable_rime", "get_context"
  }
  
  for _, func_name in ipairs(functions) do
    assert(type(detector[func_name]) == "function", func_name .. " function missing")
  end
  
  print("✓ Treesitter detector functions available")
  return true
end

function M.run_all_tests()
  print("Running input method refactoring tests...")
  
  local success = M.test_input_system()
  if success then
    M.test_detector()
  end
  
  if success then
    print("\n🎉 All input method refactoring tests passed!")
  else
    print("\n❌ Some tests failed!")
  end
  
  return success
end

-- Run tests if executed directly
if debug.getinfo(2, "S") == nil then
  M.run_all_tests()
end

return M