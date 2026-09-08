#!/usr/bin/env bash
# PostToolUse hook: auto-format files changed by apply_patch
# Dotfiles paths → hk fix; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=apply-patch-input.sh
source "$script_dir/apply-patch-input.sh"

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

home="$HOME"
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cwd" ] || cwd=$PWD

format_file() {
    local file_path="$1"

    # Dotfiles-managed paths: hk owns every formatter and its exclusions. hk
    # stages nothing: the `fix` hook sets stage = false.
    case "$file_path" in
        "$home"/*)
            if ! git -C "$home" check-ignore -q -- "$file_path" 2>/dev/null; then
                hk --cd "$home" fix "$file_path" >/dev/null 2>&1 || true
                return 0
            fi
            ;;
    esac

    # Not a dotfiles path — use generic formatters.
    case "$file_path" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json)
            if [ -x "$cwd/node_modules/.bin/prettier" ]; then
                "$cwd/node_modules/.bin/prettier" --write "$file_path" >/dev/null 2>&1 || true
            elif command -v prettier >/dev/null 2>&1; then
                prettier --write "$file_path" >/dev/null 2>&1 || true
            fi
            ;;
        *.py)
            if command -v ruff >/dev/null 2>&1; then
                ruff format --quiet "$file_path" >/dev/null 2>&1 || true
            elif command -v black >/dev/null 2>&1; then
                black --quiet "$file_path" >/dev/null 2>&1 || true
            fi
            ;;
    esac
}

while IFS= read -r patch_path; do
    [ -n "$patch_path" ] || continue

    case "$patch_path" in
        /*) file_path="$patch_path" ;;
        *) file_path="$cwd/$patch_path" ;;
    esac

    if [ -f "$file_path" ]; then
        format_file "$file_path"
    fi
done < <(printf '%s' "$input" | apply_patch_changed_paths)

exit 0
