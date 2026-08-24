#!/usr/bin/env bash
# PostToolUse hook: auto-format files after Write/Edit
# Dotfiles paths → targeted format recipe; other projects → prettier/ruff/black
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

# Cache the static justfile exclusion lists so we don't pay `just --evaluate`
# on every single zsh-function edit. The cache is keyed by the justfile mtime;
# when the justfile changes we re-evaluate once and rewrite the cache.
CACHE_DIR="$home/.cache/claude-hooks"
EXCL_CACHE="$CACHE_DIR/auto-format-exclusions.cache"
JUSTFILE="$home/justfile"

_ensure_cache_dir() {
    [ -d "$CACHE_DIR" ] || mkdir -p "$CACHE_DIR" 2>/dev/null || true
}

_load_exclusion_cache() {
    local just_mtime cache_mtime shfmt_excl shellharden_excl
    [ -f "$JUSTFILE" ] || return 1
    [ -f "$EXCL_CACHE" ] || return 1
    just_mtime=$(stat -c %Y "$JUSTFILE" 2>/dev/null || stat -f %m "$JUSTFILE" 2>/dev/null || echo "")
    cache_mtime=$(grep -E '^justfile_mtime=' "$EXCL_CACHE" 2>/dev/null | cut -d= -f2-)
    [ -n "$just_mtime" ] && [ -n "$cache_mtime" ] && [ "$just_mtime" = "$cache_mtime" ] || return 1
    shfmt_excl=$(grep -E '^shfmt_exclude_functions=' "$EXCL_CACHE" 2>/dev/null | cut -d= -f2-)
    shellharden_excl=$(grep -E '^shellharden_exclude_functions=' "$EXCL_CACHE" 2>/dev/null | cut -d= -f2-)
    printf '%s\n' "$shfmt_excl" "$shellharden_excl"
}

_update_exclusion_cache() {
    local just_mtime shfmt_excl shellharden_excl
    just_mtime=$(stat -c %Y "$JUSTFILE" 2>/dev/null || stat -f %m "$JUSTFILE" 2>/dev/null || echo "")
    [ -n "$just_mtime" ] || return 1
    shfmt_excl=$(just -f "$JUSTFILE" --evaluate shfmt_exclude_functions 2>/dev/null || echo "")
    shellharden_excl=$(just -f "$JUSTFILE" --evaluate shellharden_exclude_functions 2>/dev/null || echo "")
    _ensure_cache_dir
    {
        printf 'justfile_mtime=%s\n' "$just_mtime"
        printf 'shfmt_exclude_functions=%s\n' "$shfmt_excl"
        printf 'shellharden_exclude_functions=%s\n' "$shellharden_excl"
    } > "$EXCL_CACHE" 2>/dev/null || true
    printf '%s\n' "$shfmt_excl" "$shellharden_excl"
}

# Format ONE zsh function, honoring the justfile's exclusion lists (read via
# `just --evaluate` so there is a single source of truth) instead of running
# shfmt+shellharden over the entire functions dir on every single-file edit.
format_zsh_function() {
    local f="$1" base excl shfmt_excl shellharden_excl cache_pair
    base=$(basename "$f")
    cache_pair=$({ _load_exclusion_cache || _update_exclusion_cache; } 2>/dev/null)
    shfmt_excl=$(printf '%s\n' "$cache_pair" | sed -n '1p')
    shellharden_excl=$(printf '%s\n' "$cache_pair" | sed -n '2p')
    excl="$shfmt_excl"
    case " $excl " in *" $base "*) ;; *) shfmt -ln zsh -w -i 4 -sr "$f" 2>/dev/null || true ;; esac
    excl="$shellharden_excl"
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
