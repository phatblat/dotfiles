#!/usr/bin/env bash
# PostToolUse hook: auto-format files changed by apply_patch
# Dotfiles paths → targeted format recipe; other projects → prettier/ruff/black
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

    # Dotfiles-managed paths: run only the relevant format sub-recipe.
    case "$file_path" in
        "$home"/.gitignore)
            just -f "$home/justfile" format-gitignore >/dev/null 2>&1 || true ;;
        "$home"/.config/mise/config.toml)
            just -f "$home/justfile" format-mise >/dev/null 2>&1 || true ;;
        "$home"/.claude/settings.json|"$home"/.codex/hooks.json|"$home"/.codexbar/config.json|"$home"/.config/zed/settings.json)
            just -f "$home/justfile" format-json >/dev/null 2>&1 || true ;;
        "$home"/Library/Application\ Support/Claude/*|"$home"/Library/Application\ Support/Claude-3p/*)
            just -f "$home/justfile" format-json >/dev/null 2>&1 || true ;;
        "$home"/.config/zsh/functions/*)
            just -f "$home/justfile" format-shell >/dev/null 2>&1 || true ;;
        "$home"/.config/fish/config.fish|"$home"/.config/fish/functions/*.fish|"$home"/.config/fish/conf.d/*.fish)
            fish_indent --write "$file_path" >/dev/null 2>&1 || true ;;
        "$home"/.config/nushell/*.nu)
            ;; # no formatter; lint-nushell is syntax-check only
        "$home"/bin/*.sh)
            shfmt -ln bash -w -i 4 -sr "$file_path" >/dev/null 2>&1 || true ;;
        "$home"/scripts/*.py)
            if command -v ruff >/dev/null 2>&1; then
                ruff format --quiet "$file_path" >/dev/null 2>&1 || true
            elif command -v black >/dev/null 2>&1; then
                black --quiet "$file_path" >/dev/null 2>&1 || true
            fi
            ;;
        "$home"/justfile)
            just -f "$home/justfile" --fmt >/dev/null 2>&1 || true ;;
        *)
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
