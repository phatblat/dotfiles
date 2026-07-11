#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# Dotfiles paths → targeted format recipe; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# Format ONE JSON file the way `just format-json` would, scoped to a single file
# instead of reformatting all ~149 tracked JSON files (~7s). Mirrors the recipe's
# JSONC exclusions exactly so behavior is identical, minus the bulk cost.
format_json_file() {
    local f="$1"
    case "$f" in *.json) ;; *) return 0 ;; esac
    case "$f" in
        "$home"/.claude/skills/gstack/*) return 0 ;;                                   # vendored — never reformat
        *.jsonc.json) return 0 ;;
        "$home"/.claude/policy-limits.json) return 0 ;;                                # JSONC; recipe skips
        "$home"/Library/Application\ Support/Claude/claude_desktop_config.json) return 0 ;;  # JSONC; recipe skips
        "$home"/.config/zed/settings.json|"$home"/.config/cmux/cmux.json)
            command -v prettier >/dev/null 2>&1 && prettier --parser jsonc --write "$f" 2>/dev/null || true ;;
        *)
            jq --sort-keys --indent 2 . "$f" 2>/dev/null | sponge "$f" 2>/dev/null || true ;;
    esac
}

# Format ONE zsh function, honoring the justfile's exclusion lists (read via
# `just --evaluate` so there is a single source of truth) instead of running
# shfmt+shellharden over the entire functions dir on every single-file edit.
format_zsh_function() {
    local f="$1" base excl
    base=$(basename "$f")
    excl=$(just -f "$home/justfile" --evaluate shfmt_exclude_functions 2>/dev/null || echo "")
    case " $excl " in *" $base "*) ;; *) shfmt -ln zsh -w -i 4 -sr "$f" 2>/dev/null || true ;; esac
    excl=$(just -f "$home/justfile" --evaluate shellharden_exclude_functions 2>/dev/null || echo "")
    case " $excl " in *" $base "*) ;; *) shellharden --replace "$f" 2>/dev/null || true ;; esac
}

# Dotfiles-managed paths: run only the relevant format sub-recipe
case "$file_path" in
    "$home"/.gitignore)
        just -f "$home/justfile" format-gitignore 2>/dev/null || true ;;
    "$home"/.config/mise/config.toml)
        just -f "$home/justfile" format-mise 2>/dev/null || true ;;
    "$home"/.claude/settings.json|"$home"/.codexbar/config.json|"$home"/.config/zed/settings.json)
        format_json_file "$file_path" ;;
    "$home"/Library/Application\ Support/Claude/*|"$home"/Library/Application\ Support/Claude-3p/*)
        format_json_file "$file_path" ;;
    "$home"/.config/zsh/functions/*)
        format_zsh_function "$file_path" ;;
    "$home"/.config/fish/config.fish|"$home"/.config/fish/functions/*.fish|"$home"/.config/fish/conf.d/*.fish)
        fish_indent --write "$file_path" 2>/dev/null || true ;;
    "$home"/.config/nushell/*.nu)
        ;; # no formatter; lint-nushell is syntax-check only
    "$home"/bin/*.sh)
        shfmt -ln bash -w -i 4 -sr "$file_path" 2>/dev/null || true ;;
    "$home"/scripts/*.py)
        if command -v ruff >/dev/null 2>&1; then
            ruff format --quiet "$file_path" 2>/dev/null || true
        elif command -v black >/dev/null 2>&1; then
            black --quiet "$file_path" 2>/dev/null || true
        fi
        ;;
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
