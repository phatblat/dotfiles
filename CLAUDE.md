# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Dotfiles repository — cross-machine config sync. Home directory (`~`) is the git repo root.

**Nested repo warning:** Many subdirectories (especially `dev/`) are separate git repos. cwd is already `~`; use bare git or `git -C ~`, never `cd ~ &&`. Confirm which repo you're in before committing.

## Commands

- `just check` — full quality gate: lint, spelling (typos), tests
- `just lint` — gitignore sort check, ruff, all shell linters, justfile/mise fmt check
- `just test` — bats tests in `~/tests/`; single file: `bats ~/tests/<name>.bats`
- `just format` — formats .gitignore, mise config, JSON/JSONC configs, and zsh functions (shfmt + shellharden)
- `just lint-zsh` / `lint-fish` / `lint-nushell` / `lint-bin` — per-shell linting
- `just add <tool>` / `just remove <tool>` / `just upgrade` — mise tool management

## Key Directories

- `.config/` — Shell configs (zsh, fish, nushell), tool configs (zed, mise, home-manager)
- `bin/` — Custom utility scripts
- `scripts/` — Repo maintenance scripts (sort-gitignore, sort-tools.py, gastown helpers)
- `tests/` — Bats test suite
- `dev/` — Development workspace organized by language/framework/org (separate repos, not part of dotfiles)
- `docs/functions.md` — Complete inventory of shell functions/aliases
- `docs/tooling-dimensions.md` — How package managers, shells, and agent harnesses each stay in sync (or intentionally don't)
- `docs/package-management.md` — mise/Homebrew/Nix roles and drift-checking

## Shell Architecture

1. **Zsh (Primary)** — `~/.zshrc`, functions in `~/.config/zsh/functions/*`
2. **Fish (Secondary)** — `~/.config/fish/config.fish`
3. **Nushell (Active)** — `~/.config/nushell/config.nu`
4. **Bash (Minimal)** — `~/.bashrc`

Shell function conventions are in the `shell-functions` rule (loads when editing shell config files).

## Project Context

Primarily shell scripting (Zsh), with Go, Ruby, Python, Swift, and other languages. Git workflow conventions are in the `git-workflow` rule.

## Code Search

Use **ast-grep** (`sg`) for code search, not grep/ripgrep/sed.

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available gstack skills: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/setup-gbrain`, `/retro`, `/investigate`, `/document-release`, `/document-generate`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`.

## Special Notes

- **bat** replaces cat in Zsh (syntax highlighting, git integration)
- **timeout/gtimeout** not installed
- **Tool installation priority:**
  1. `mise search`/`mise use` for mise-managed tools
  2. `nix profile install nixpkgs#<package>` for Nix packages
  3. `brew search`/`brew install` as fallback
- Tool versions: run `mise ls` (never hardcode versions — they go stale)
- Check for tools installed via both mise and Homebrew with `just package-audit` (see `docs/package-management.md`)
- Just recipes: run `just --list`
- `.gitignore` uses negation-aware sorted ordering — after editing, run `just format-gitignore` (checked by `just lint-gitignore`)
- Some `.json` files are actually JSONC and must not be jq-formatted: `.config/zed/settings.json`, `.config/cmux/cmux.json`, `.claude/policy-limits.json` (see `format-json` recipe)
- Zsh functions are auto-formatted by shfmt/shellharden via `just format-shell`; files using zsh-only syntax are excluded via Justfile variables

## MCP Tools: code-review-graph

**This project has a knowledge graph. Use code-review-graph MCP tools BEFORE Grep/Glob/Read.** Full tool reference is in the `explore-codebase` skill.
