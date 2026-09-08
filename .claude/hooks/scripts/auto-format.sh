#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# Dotfiles paths → hk fix; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# A path the dotfiles repo would track (inside $HOME and not gitignored) goes to
# hk, which owns every formatter and its exclusions. hk stages nothing: the
# `fix` hook sets stage = false.
case "$file_path" in
    "$home"/*)
        if ! git -C "$home" check-ignore -q -- "$file_path" 2>/dev/null; then
            hk --cd "$home" fix "$file_path" >/dev/null 2>&1 || true
            exit 0
        fi
        ;;
esac

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
