-- Test script for the refactored LM-nvim configuration
-- This script validates that the core modules load correctly

local function test_core_modules()
  print("Testing LM-nvim Core Module Refactoring...")
  
  -- Test 1: Core module loading
  local core_ok, core = pcall(require, "core")
  if core_ok then
    print("✓ Core module loads successfully")
  else
    print("✗ Core module failed to load: " .. tostring(core))
    return false
  end
  
  -- Test 2: Math engines
  local math_ok, math_engines = pcall(require, "core.math.engines")
  if math_ok then
    print("✓ Math engines module loads successfully")
    
    -- Test engine constants
    if math_engines.ENGINES then
      print("✓ Engine constants defined")
    else
      print("✗ Engine constants missing")
      return false
    end
    
    -- Test presets
    if math_engines.presets then
      print("✓ Engine presets defined")
    else
      print("✗ Engine presets missing")
      return false
    end
  else
    print("✗ Math engines failed to load: " .. tostring(math_engines))
    return false
  end
  
  -- Test 3: Language modules
  local lang_ok, languages = pcall(require, "languages")
  if lang_ok then
    print("✓ Language manager loads successfully")
  else
    print("✗ Language manager failed to load: " .. tostring(languages))
    return false
  end
  
  -- Test 4: Core configuration modules
  local config_modules = {"core.config", "core.autocmds", "core.keymaps"}
  for _, module in ipairs(config_modules) do
    local ok, mod = pcall(require, module)
    if ok then
      print("✓ " .. module .. " loads successfully")
    else
      print("✗ " .. module .. " failed to load: " .. tostring(mod))
      return false
    end
  end
  
  print("\n🎉 All core modules loaded successfully!")
  print("📝 Refactoring validation complete.")
  return true
end

-- Only run test if this file is executed directly
if debug.getinfo(2) == nil then
  test_core_modules()
end

return {
  test_core_modules = test_core_modules
}