# Input Method Management Refactoring

## Overview

This document describes the refactoring of the input method management system in LM-nvim, specifically the rime_ls (Chinese input) and dictionary_lsp (English input) automatic toggling feature.

## Problem

The previous implementation had several maintainability issues:

1. **Scattered Logic**: Input method toggling was spread across multiple files:
   - `lua/lsp/rime_ls.lua` - Basic rime_ls setup
   - `lua/lsp/dictionary.lua` - Dictionary LSP setup  
   - `lua/util/math_autochange.lua` - Core toggling logic
   - `lua/util/rime_ls.lua` - UI-related functions
   - `lua/util/latex.lua` - Treesitter environment detection

2. **Global State Management**: Used scattered global variables (`_G.rime_toggled`, `_G.rime_ls_active`, etc.)

3. **Mixed Concerns**: The `math_autochange.lua` file handled both input method toggling AND other cursor-based logic

4. **Inconsistent Treesitter Usage**: Environment detection was duplicated with slight variations

## Solution: Core Input Management System

### New Architecture

```
lua/core/input/
├── init.lua                 # Main input method coordinator
├── state_manager.lua        # Centralized state management
├── treesitter_detector.lua  # Unified environment detection
├── rime_manager.lua         # Rime-specific logic
└── dictionary_manager.lua   # Dictionary-specific logic
```

### Key Features

#### 1. Unified State Management

The new `state_manager.lua` replaces scattered global variables with a proper state management system:

```lua
local input = require("core.input")
local state = input.state

-- Check current state
local is_rime_enabled = state.is_rime_enabled()
local context = input.detector.get_context()
```

#### 2. Treesitter-Based Environment Detection

The `treesitter_detector.lua` consolidates all environment detection logic:

```lua
local detector = require("core.input.treesitter_detector")

-- Check if rime should be disabled
if detector.should_disable_rime() then
  -- In math/formula environment - use dictionary
else
  -- In text environment - use rime
end
```

#### 3. Automatic Toggling

The system automatically switches between rime_ls and dictionary_lsp based on cursor position:

- **Math environments**: Rime disabled, dictionary enabled
- **Text environments**: Rime enabled, dictionary disabled
- **Manual override**: User can still toggle manually with `<leader>rr`

#### 4. Backward Compatibility

All existing APIs are preserved through compatibility layers:

```lua
-- Old API still works
require("lsp.rime_ls").toggle_rime()
require("util.rime_ls").rime_toggle_word()

-- But now redirects to new system
require("core.input").manual_toggle_rime()
```

### Supported File Types

- `.tex` (LaTeX)
- `.typ` (Typst) 
- `.md` (Markdown)

### Environment Detection

The system detects these contexts for automatic switching:

- **Math zones**: `displayed_equation`, `inline_formula`, `math_environment`
- **TikZ environments**: `tikzpicture`
- **LaTeX command brackets**: `\command{cursor_here}`

## Migration Guide

### For Users

No changes needed! All existing keybindings and functionality work exactly the same:

- `<leader>rr` - Toggle rime manually
- `<leader>rs` - Sync rime settings
- `<leader>ri` - Debug input method state (new)

### For Developers

The new system provides a cleaner API:

```lua
-- Old scattered approach
require("lsp.rime_ls").setup_rime()
require("lsp.dictionary").dictionary_setup()
require("util.math_autochange") -- Side effects

-- New unified approach  
require("core.input").setup()
```

## Implementation Details

### State Management

The state manager maintains both internal state and global variables for compatibility:

```lua
-- Internal state (new)
local state = require("core.input.state_manager")
state.set_rime_enabled(true)

-- Global variables (legacy compatibility)
_G.rime_toggled = true
_G.rime_ls_active = true
```

### Autocmd Coordination

The system uses a single set of autocmds for all file types:

```lua
vim.api.nvim_create_autocmd("CursorMovedI", {
  pattern = { "*.tex", "*.typ", "*.md" },
  callback = auto_toggle_input_methods,
})
```

### LSP Integration

LSP configurations remain unchanged in the `/lsp/` directory as requested, but setup is now handled through the managers:

```lua
-- rime_manager.lua handles the actual LSP setup
-- lsp/rime_ls.lua becomes a thin compatibility layer
```

## Benefits

1. **Reduced Duplication**: ~150 lines of scattered logic consolidated
2. **Better Organization**: Clear separation of concerns
3. **Enhanced Maintainability**: Single responsibility modules
4. **Improved Debugging**: Centralized state and context inspection
5. **Future Extensibility**: Easy to add new input methods or file types

## Testing

Run the validation test:

```lua
:lua require("test.input_refactoring_test").run_all_tests()
```

This verifies:
- All modules load correctly
- State management works
- Compatibility layers function
- API functions are available

## Configuration

The system initializes automatically through the core module:

```lua
-- In lua/core/init.lua
require("core.input").setup()  -- Now part of core initialization
```

No additional configuration needed for basic functionality.