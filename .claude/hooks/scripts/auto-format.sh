#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# Dotfiles paths → just format; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# Dotfiles-managed paths: use `just format` (authoritative for this repo)
case "$file_path" in
    "$home"/.gitignore)                            ;; # format-gitignore
    "$home"/.config/mise/config.toml)              ;; # format-mise
    "$home"/.claude/settings.json)                 ;; # format-json
    "$home"/.codexbar/config.json)                 ;; # format-json
    "$home"/Library/Application\ Support/Claude/*) ;; # format-json
    "$home"/Library/Application\ Support/Claude-3p/*) ;; # format-json
    "$home"/.config/zed/settings.json)             ;; # format-json
    "$home"/.config/zsh/functions/*)               ;; # format-shell, lint-zsh
    "$home"/.config/fish/config.fish)              ;; # lint-fish
    "$home"/.config/fish/functions/*.fish)         ;; # lint-fish
    "$home"/.config/fish/conf.d/*.fish)            ;; # lint-fish
    "$home"/.config/nushell/*.nu)                  ;; # lint-nushell
    "$home"/bin/*.sh)                              ;; # lint-bin
    "$home"/scripts/*.py)                          ;; # lint-python
    "$home"/justfile)                              ;; # just --fmt
    *)
        # Not a dotfiles path — use generic formatters
        case "$file_path" in
            *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json)
                if [ -x "./node_modules/.bin/prettier" ]; then
                    ./node_modules/.bin/prettier --write "$file_path" 2>/dev/null || true
                elif command -v prettier >/dev/null 2>&1; then
                    prettier --write "$file_path" 2>/dev/null || true
                fi
                ;;
            *.py)
                if command -v ruff >/dev/null 2>&1; then
                    ruff format --quiet "$file_path" 2>/dev/null || true
                elif command -v black >/dev/null 2>&1; then
                    black --quiet "$file_path" 2>/dev/null || true
                fi
                ;;
        esac
        exit 0
        ;;
esac

just format 2>/dev/null || true
exit 0
