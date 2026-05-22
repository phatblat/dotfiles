# CLAUDE.md

Dotfiles repository — cross-machine config sync. Home directory (`~`) is the git repo root.

## Key Directories

- `.config/` — Shell configs (zsh, fish, nushell), tool configs (zed, mise, home-manager)
- `bin/` — Custom utility scripts
- `dev/` — Development workspace organized by language/framework/org
- `docs/functions.md` — Complete inventory of shell functions/aliases

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

## Special Notes

- **bat** replaces cat in Zsh (syntax highlighting, git integration)
- **timeout/gtimeout** not installed
- **Tool installation priority:**
  1. `mise search`/`mise use` for mise-managed tools
  2. `nix profile install nixpkgs#<package>` for Nix packages
  3. `brew search`/`brew install` as fallback
- Tool versions: run `mise ls` (never hardcode versions — they go stale)
- Just recipes: run `just --list`

## MCP Tools: code-review-graph

**This project has a knowledge graph. Use code-review-graph MCP tools BEFORE Grep/Glob/Read.** Full tool reference is in the `explore-codebase` skill.
