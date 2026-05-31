#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# Dotfiles paths → targeted format recipe; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# Dotfiles-managed paths: run only the relevant format sub-recipe
case "$file_path" in
    "$home"/.gitignore)
        just -f "$home/justfile" format-gitignore 2>/dev/null || true ;;
    "$home"/.config/mise/config.toml)
        just -f "$home/justfile" format-mise 2>/dev/null || true ;;
    "$home"/.claude/settings.json|"$home"/.codexbar/config.json|"$home"/.config/zed/settings.json)
        just -f "$home/justfile" format-json 2>/dev/null || true ;;
    "$home"/Library/Application\ Support/Claude/*|"$home"/Library/Application\ Support/Claude-3p/*)
        just -f "$home/justfile" format-json 2>/dev/null || true ;;
    "$home"/.config/zsh/functions/*|"$home"/.config/fish/config.fish|"$home"/.config/fish/functions/*.fish|"$home"/.config/fish/conf.d/*.fish|"$home"/.config/nushell/*.nu|"$home"/bin/*.sh|"$home"/scripts/*.py)
        just -f "$home/justfile" format-shell 2>/dev/null || true ;;
    "$home"/justfile)
        just -f "$home/justfile" --fmt 2>/dev/null || true ;;
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
        ;;
esac

exit 0
