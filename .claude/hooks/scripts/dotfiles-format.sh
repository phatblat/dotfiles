#!/usr/bin/env bash
# PostToolUse hook: run `just format` after editing files managed by format/lint recipes
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

[ -z "$file_path" ] && exit 0
[ -f "$file_path" ] || exit 0

home="$HOME"

case "$file_path" in
    "$home"/.gitignore)                                         ;; # format-gitignore
    "$home"/.config/mise/config.toml)                           ;; # format-mise
    "$home"/.claude/settings.json)                              ;; # format-json
    "$home"/.codexbar/config.json)                              ;; # format-json
    "$home"/Library/Application\ Support/Claude/*)              ;; # format-json
    "$home"/Library/Application\ Support/Claude-3p/*)           ;; # format-json
    "$home"/.config/zed/settings.json)                          ;; # format-json
    "$home"/.config/zsh/functions/*)                            ;; # format-shell, lint-zsh
    "$home"/.config/fish/config.fish)                           ;; # lint-fish
    "$home"/.config/fish/functions/*.fish)                      ;; # lint-fish
    "$home"/.config/fish/conf.d/*.fish)                         ;; # lint-fish
    "$home"/.config/nushell/*.nu)                               ;; # lint-nushell
    "$home"/bin/*.sh)                                           ;; # lint-bin
    "$home"/scripts/*.py)                                       ;; # lint-python
    "$home"/justfile)                                           ;; # just --fmt
    *) exit 0 ;;
esac

just format 2>/dev/null || true
exit 0
