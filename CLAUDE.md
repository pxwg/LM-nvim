# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A minimalist Neovim configuration focused on bilingual (Chinese/English) academic writing, with LaTeX/Typst support, a Zettelkasten note system, and AI integration. macOS-optimized with Hammerspoon integration for Zathura PDF preview.

## Plugin Manager

**lazy.nvim** is used as the plugin manager. Entry point: `init.lua` → `lua/config/lazy.lua`.

Plugin specs live in `lua/plugins/` following the naming convention `{category}.{plugin-name}.lua` (e.g., `edit.blink.lua`, `ui.catppuccin.lua`, `ai.copilot.lua`).

Lazy-loading strategies used:
- `event = "VeryLazy"` / `event = "InsertEnter"` for event-driven loading
- `event = "LazyFile"` (custom event defined in `util/lazyfile.lua`) for file-type loading
- `ft = {...}` for filetype-specific plugins
- `cmd = "..."` for command-triggered loading

## Configuration Structure

```
lua/
├── config/
│   ├── lazy.lua       # Plugin manager bootstrap & disabled builtins
│   ├── options.lua    # vim options, enabled LSP servers list
│   ├── keymap.lua     # Global keybindings (~500 lines)
│   └── autocmd.lua    # Auto-commands
├── plugins/           # Plugin specs (lazy.nvim format)
├── util/              # Custom utility modules
├── lsp/               # LSP client configuration
├── conceal/           # Math symbol concealing for LaTeX/Typst
└── zk_scripts.lua     # Zettelkasten note system (~37KB)
```

## Core Systems

### Input Method (Primary Feature)
`lua/plugins/edit.blink.lua` — blink.cmp completion framework integrating rime-ls (Rime IME) for Chinese input. Key behaviors: `<space>` accepts rime suggestions; automatic punctuation switching between Chinese/English modes; math environment detection disables Chinese input.

### LSP
`lua/lsp/` — nvim-lspconfig setup. Enabled server list is in `lua/config/options.lua`. Custom LSP: `zk-lsp` for the note system.

### Formatting
`lua/plugins/edit.conform.lua` — conform.nvim with per-filetype formatters. Custom Rust binary at `trim_blank_fmt/target/release/trim_blank_fmt` for trailing whitespace. `autocorrect` handles Chinese/English mixed-text formatting.

### Zettelkasten Notes
The note system spans multiple files:
- `zk_scripts.lua` — core note graph logic (ID-based references `<1234567890>`, bidirectional links, tag system)
- `lua/util/note_node.lua` — graph data structures
- `lua/util/note_telescope.lua` — Telescope picker integration
- `lua/lsp/zk_lsp.lua` — custom LSP for note navigation
- `lua/plugins/edit.zk_telescope.lua` — search commands (`:Zk search`, `:Zk alias`, etc.)

Notes use Typst format with metadata headers.

### Keybindings
Leader: `<space>`, Local leader: `\`. All keybindings in `lua/config/keymap.lua`. `util/fast_keymap.lua` and `util/better_keymap.lua` provide helpers.

### macOS/Hammerspoon
`lua/util/hammerspoon.lua` — bridges Neovim with Zathura PDF viewer for consistent keybindings via the `hs` CLI (registered as a global in `.luarc.json`).

## Adding Plugins

Create a new file in `lua/plugins/` following the `{category}.{plugin-name}.lua` convention. Return a lazy.nvim spec table. Use `event = "VeryLazy"` for general-purpose plugins unless a more specific trigger is appropriate.

## Mason

LSP servers and formatters are managed by Mason (`<leader>cm` opens Mason UI). No manual installation commands needed — Mason handles tool installation.
