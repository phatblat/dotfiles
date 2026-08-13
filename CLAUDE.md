# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dotfiles repository — cross-machine config sync. Home directory (`~`) is the git repo root.

**Nested repo warning:** Many subdirectories (especially `dev/`) are separate git repos. cwd is already `~`; use bare git or `git -C ~`, never `cd ~ &&`. Confirm which repo you're in before committing.

## Path Scope

- Treat `.` as this repository's root. For repo-local shell operations, use `.` or `./relative/path` instead of absolute paths such as `/Users/phatblat/...`.
- Never start filesystem searches at `/` when the repository contains the intended search scope; use commands such as `find . ...` to remain within Claude's working-directory boundary and avoid permission prompts.
- Access paths outside this repository only when the task explicitly requires it.

## Key Directories

- `.config/` — Shell configs (zsh, nushell), tool configs (zed, mise, home-manager)
- `bin/` — Custom utility scripts
- `scripts/` — Repo maintenance scripts (sort-gitignore, sort-tools.py, gastown helpers)
- `tests/` — Bats test suite
- `dev/` — Development workspace organized by language/framework/org (separate repos, not part of dotfiles)
- `docs/functions.md` — Complete inventory of shell functions/aliases
- `docs/tooling-dimensions.md` — How package managers, shells, and agent harnesses each stay in sync (or intentionally don't)
- `docs/package-management.md` — mise/Homebrew/Nix roles and drift-checking

## Shell Architecture

1. **Nushell (Primary)** — `~/.config/nushell/config.nu`
2. **Zsh (Fallback)** — `~/.zshrc`, functions in `~/.config/zsh/functions/*`
3. **Bash (Minimal)** — `~/.bashrc`

Shell function conventions are in the `shell-functions` rule (loads when editing shell config files).

## Project Context

Primarily shell scripting (Zsh), with Go, Ruby, Python, Swift, and other languages. Git workflow conventions are in the `git-workflow` rule.

## Code Search

Use **ast-grep** (`sg`) for code search, not grep/ripgrep/sed.

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools. gstack skills are auto-discovered each session — invoke by name as needed.

## Special Notes

- **bat** replaces cat in Zsh (syntax highlighting, git integration)
- **Tool installation priority:**
  1. `mise search`/`mise use` for mise-managed tools
  2. `nix profile install nixpkgs#<package>` for Nix packages
  3. `brew search`/`brew install` as fallback
- Tool versions: run `mise ls` (never hardcode versions — they go stale)
- Check for tools installed via both mise and Homebrew with `just package-audit` (see `docs/package-management.md`)
- Just recipes: run `just --list`
