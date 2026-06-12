# AGENTS.md

This file provides repository-specific guidance for Codex and other coding agents working in this Neovim configuration.

## Repository Conventions

Commit messages should follow the existing concise Conventional Commit style:
`type(scope): summary`, for example `feat(copilot-chat): add guarded tool execution`.
Use `type: summary` only when a scope would not add useful context. Keep the
type lowercase and limited to the existing set when possible, especially `feat`,
`fix`, `chore`, and `docs`. Use short module-oriented scopes such as `codex`,
`sidekick`, `typst`, `math-conceal`, `img-clip`, or `guh`. Keep summaries
concise, lowercase, imperative, and without a trailing period.

CopilotChat tools that can run commands, scan files, call MCP tools, or otherwise block must be bounded by timeout and output guards. Prefer `bounded_system()` for shell-backed tools so long scans can be terminated and surfaced as a timeout result instead of blocking Neovim.
