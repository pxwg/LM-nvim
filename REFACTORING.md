# LM-nvim Configuration Refactoring Documentation

## Overview

This document describes the refactoring of the LM-nvim configuration to improve maintainability, modularity, and reduce code duplication, particularly in mathematical computation handling.

## Key Improvements

### 1. Core Module Structure

The new modular structure separates concerns into distinct modules:

```
lua/
├── core/                     # Core configuration modules
│   ├── init.lua             # Core module loader and setup
│   ├── config.lua           # Basic vim settings and LSP configuration
│   ├── autocmds.lua         # Essential autocmds
│   ├── keymaps.lua          # Core keymaps
│   └── math/                # Mathematical computation engine
│       ├── engines.lua      # Unified computation engines
│       ├── job_runner.lua   # Job execution abstraction
│       └── latex_processor.lua # LaTeX processing utilities
├── languages/               # Language-specific configurations
│   ├── init.lua            # Language configuration manager
│   ├── tex/init.lua        # LaTeX-specific setup
│   ├── markdown/init.lua   # Markdown-specific setup
│   └── typst/init.lua      # Typst-specific setup
└── lsp/                    # LSP configurations (unchanged)
```

### 2. Mathematical Computation Consolidation

**Before**: Duplicated computation logic across multiple files:
- `luasnip/tex/mathematica.lua`
- `luasnip/tex/sympy.lua` 
- `luasnip/markdown/mathematica.lua`

**After**: Unified computation engine with:
- Single job execution abstraction
- Standardized LaTeX preprocessing
- Multiple computation backends (Mathematica, SymPy, LaTeX2LaTeX, Quantum)
- Consistent error handling and timeouts

### 3. Language-Specific Organization

Each language now has its own module with:
- Autocmds specific to that language
- Keymaps active only in that language's buffers
- File type specific settings
- Clear separation from core functionality

## Migration Guide

### For Users

The refactoring is backward compatible. No changes are needed to existing configurations or workflows.

### For Developers

#### Adding New Computation Engines

```lua
-- In core/math/engines.lua
M.ENGINES.NEW_ENGINE = "new_engine"

-- In core/math/job_runner.lua
M.run_new_engine = function(input, options)
  -- Implementation
end

-- In core/math/engines.lua
M.presets.new_engine_preset = function()
  return M.create_computation_snippet(M.ENGINES.NEW_ENGINE, {"new", "new"})
end
```

#### Adding New Languages

```lua
-- Create lua/languages/newlang/init.lua
local M = {}
local autocmd = vim.api.nvim_create_autocmd

M.setup = function()
  autocmd("FileType", {
    pattern = { "newlang" },
    callback = function()
      -- Language-specific setup
    end,
  })
end

return M

-- Update lua/languages/init.lua
M.languages = {
  "tex",
  "markdown", 
  "typst",
  "newlang" -- Add here
}
```

## Architecture Benefits

1. **Reduced Duplication**: Mathematical computation logic unified
2. **Better Separation**: Clear boundaries between core and language-specific code
3. **Enhanced Maintainability**: Each module has a single responsibility
4. **Preserved Functionality**: All existing features work unchanged
5. **Future Extensibility**: Easy to add new languages or computation engines
6. **Improved Testing**: Modular structure enables better unit testing

## Technical Details

### Core Module Loading

The new loading sequence in `lua/config/lazy.lua`:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    -- Load core configuration using new modular system
    require("core").setup()
    -- ... rest of initialization
  end,
})
```

### Mathematical Computation Flow

1. Snippet triggered (e.g., `mcal x^2 mcals`)
2. Engine extracts content using delimiters
3. LaTeX processor cleans and formats input
4. Job runner executes external tool (wolframscript/python3)
5. Result returned to snippet

### Engine Abstraction

All computation engines share the same interface:

```lua
local result = math_engines.compute(
  math_engines.ENGINES.MATHEMATICA,
  "x^2 + 2x + 1",
  { original_input = "x^2 + 2x + 1" }
)
```

## Testing

Run the refactoring validation test:

```lua
:lua require("test.refactoring_test").test_core_modules()
```

## Future Enhancements

1. Add more computation engines (Sage, Julia, etc.)
2. Implement computation result caching
3. Add syntax highlighting for computation blocks
4. Create language server integration for mathematical expressions
5. Add support for more file formats (AsciiMath, etc.)