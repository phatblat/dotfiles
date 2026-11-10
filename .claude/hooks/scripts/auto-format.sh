#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# A dotfiles checkout file (matching the real hook script's git common dir)
# routes to hk; every other file routes to generic prettier/ruff/black.
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# Canonicalize script and file paths.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(realpath "$script_dir")"
file_path="$(realpath "$file_path")"

before=$(git hash-object -- "$file_path" 2>/dev/null || shasum "$file_path" | cut -d' ' -f1)

record_if_changed() {
    local after
    after=$(git hash-object -- "$file_path" 2>/dev/null || shasum "$file_path" | cut -d' ' -f1)
    if [ "$before" != "$after" ] && [ -f "$home/scripts/flywheel-record.py" ]; then
        python3 "$home/scripts/flywheel-record.py" scaffold \
            --scaffold claude-auto-format \
            --harness claude \
            --detail "formatted $(basename "$file_path")" >/dev/null 2>&1 || true
    fi
}
trap record_if_changed EXIT

# Bundle roots are laid out as <root>/.claude/hooks/scripts. The checkout root
# is three canonical directories above this script, and the file's canonical
# common dir comes from its containing directory.
checkout_root="$(realpath "$script_dir/../../..")"
script_common_dir="$(git -C "$checkout_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"
file_common_dir="$(git -C "$(dirname "$file_path")" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"

if [ -n "$script_common_dir" ] && [ "$script_common_dir" = "$file_common_dir" ]; then
    hk --cd "$checkout_root" fix "$file_path" >/dev/null 2>&1 || true
    exit 0
fi

# Ignored inside their repo are not formatted.
file_top="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || printf '')"
if [ -n "$file_top" ] && git -C "$file_top" check-ignore -q -- "$file_path" 2>/dev/null; then
    exit 0
fi

# Not this checkout — generic formatters only.
case "$file_path" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json)
        if [ -x "./node_modules/.bin/prettier" ]; then
            ./node_modules/.bin/prettier --write "$file_path" >/dev/null 2>&1 || true
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

exit 0
