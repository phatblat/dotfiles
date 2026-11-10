#!/usr/bin/env bash
# PostToolUse hook: auto-format files changed by apply_patch
# A dotfiles checkout file (matching the hook's canonical common dir)
# routes to hk; every other file routes to generic prettier/ruff/black.
set -euo pipefail

input=$(cat)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=apply-patch-input.sh
source "$script_dir/apply-patch-input.sh"

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

home="$HOME"
buffer_cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$buffer_cwd" ] || buffer_cwd=$PWD

canonical_file_path() {
    realpath "$1"
}

format_file() {
    local file_path="$1"

    file_path="$(canonical_file_path "$file_path")"

    local script_common_dir file_common_dir checkout_root
    # The hook script directory nests three levels below its checkout root:
    # <root>/.codex/hooks/scripts.
    checkout_root="$(realpath "$script_dir/../../..")"
    script_common_dir="$(git -C "$checkout_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"
    file_common_dir="$(git -C "$(dirname "$file_path")" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"

    if [ -n "$script_common_dir" ] && [ "$script_common_dir" = "$file_common_dir" ]; then
        # hk owns the shipping rubric: staged nothing, fix everything...
        hk --cd "$checkout_root" fix "$file_path" >/dev/null 2>&1 || true
        return 0
    fi

    file_top="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || printf '')"
    if [ -n "$file_top" ] && git -C "$file_top" check-ignore -q -- "$file_path" 2>/dev/null; then
        return 0
    fi

    # Not dotfiles code paths — generic formatters.
    case "$file_path" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json)
            prettier_bin="$buffer_cwd/node_modules/.bin/prettier"
            if [ -x "$prettier_bin" ]; then
                "$prettier_bin" --write "$file_path" >/dev/null 2>&1 || true
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
        *) file_path="$buffer_cwd/$patch_path" ;;
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
