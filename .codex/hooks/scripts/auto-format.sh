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

changed_count=0
while IFS= read -r patch_path; do
    [ -n "$patch_path" ] || continue

    case "$patch_path" in
        /*) file_path="$patch_path" ;;
        *) file_path="$cwd/$patch_path" ;;
    esac

    if [ -f "$file_path" ]; then
        before=$(git hash-object -- "$file_path" 2>/dev/null || shasum "$file_path" | cut -d' ' -f1)
        format_file "$file_path"
        after=$(git hash-object -- "$file_path" 2>/dev/null || shasum "$file_path" | cut -d' ' -f1)
        if [ "$before" != "$after" ]; then
            changed_count=$((changed_count + 1))
        fi
    fi
done < <(printf '%s' "$input" | apply_patch_changed_paths)

if [ "$changed_count" -gt 0 ] && [ -f "$home/scripts/flywheel-record.py" ]; then
    python3 "$home/scripts/flywheel-record.py" scaffold \
        --scaffold codex-auto-format \
        --harness codex \
        --detail "formatted ${changed_count} file(s)" >/dev/null 2>&1 || true
fi

exit 0
