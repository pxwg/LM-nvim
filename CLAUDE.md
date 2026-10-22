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
├── util/              # Custom utility modules (note_info.lua: local note metadata)
└── conceal/           # Math symbol concealing for LaTeX/Typst
```

## Core Systems

### Input Method (Primary Feature)
`lua/plugins/edit.blink.lua` — blink.cmp completion framework integrating rime-ls (Rime IME) for Chinese input. Key behaviors: `<space>` accepts rime suggestions; automatic punctuation switching between Chinese/English modes; math environment detection disables Chinese input.

### LSP
`lsp/` — LSP configurations. Enabled server list is in `lua/config/options.lua`. The default wiki uses the project-owned `wiki-ocaml` LSP and Tinymist setup. `zettyp-lsp` remains available for legacy projects.

### Formatting
`lua/plugins/edit.conform.lua` — conform.nvim with per-filetype formatters. Custom Rust binary at `trim_blank_fmt/target/release/trim_blank_fmt` for trailing whitespace. `autocorrect` handles Chinese/English mixed-text formatting.

### Zettelkasten Notes
The default wiki is `~/wiki-ocaml`, configured once through `vim.g.wiki_root` in `lua/config/options.lua`:
- `lua/util/wiki.lua` — default root, project-aware preview paths, Dashboard entry and global `:Zet`
- `lua/plugins/edit.zettypst.nvim.lua` — Lazy local-directory spec for the pinned OCaml plugin; inherits `.zettypst/nvim/init.lua` from the default wiki
- Project-owned setup scopes LSP/rendering to wiki files; global search can use the default wiki without changing cwd. Other explicit knowledge projects are not redirected.
- Old `~/wiki` rendering paths are legacy compatibility rules, not the default wiki resolver.
- `lsp/zettyp-lsp.lua` — legacy note navigation LSP
- `lua/util/note_info.lua` — pure local title/metadata extraction for Snacks and completion, supporting numeric and timestamp note IDs

Do not reintroduce the retired external note CLI or its workspace/blackboard integration.

Notes use Typst format with metadata headers.

### Keybindings
Leader: `<space>`, Local leader: `\`. All keybindings in `lua/config/keymap.lua`. `util/fast_keymap.lua` and `util/better_keymap.lua` provide helpers.

### macOS/Hammerspoon
`lua/util/hammerspoon.lua` — bridges Neovim with Zathura PDF viewer for consistent keybindings via the `hs` CLI (registered as a global in `.luarc.json`).

## Adding Plugins

Create a new file in `lua/plugins/` following the `{category}.{plugin-name}.lua` convention. Return a lazy.nvim spec table. Use `event = "VeryLazy"` for general-purpose plugins unless a more specific trigger is appropriate.

## Mason

LSP servers and formatters are managed by Mason (`<leader>cm` opens Mason UI). No manual installation commands needed — Mason handles tool installation.

## CopilotChat Tools

CopilotChat tools that run commands, scan files, call MCP tools, or otherwise block must be bounded by timeout and output guards. Prefer `bounded_system()` for shell-backed tools so long scans can terminate and return timeout or truncation results instead of blocking Neovim.

## Sidekick.nvim with Wiki Integration

The `sidekick.nvim` plugin is configured with two Claude Code integrations:

- `<leader>ac` - Opens Claude Code normally
- `<leader>aw` - Opens Claude Code with the default wiki directory (`~/wiki-ocaml`) added via `--add-dir` flag

This enables Claude Code to access the Zettelkasten note system when working on tasks related to the wiki.
