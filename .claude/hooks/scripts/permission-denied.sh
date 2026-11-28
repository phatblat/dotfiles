#!/usr/bin/env bash
# PermissionDenied — record which tool and command family auto mode refused,
# so optimize-harness can measure missing-allow-rule friction. Logs the tool
# name (whitespace collapsed, capped at 128 chars) and the basename of the
# first command word only when that word is a plain name or path; an env
# assignment logs as <env-assign> and any other shell syntax as <other>.
# Arguments, redirect targets and quoted paths are never logged.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '(.tool_name // "unknown") | tostring | gsub("\\s+"; " ") | .[0:128]')
FIRST_WORD=$(printf '%s' "$INPUT" | jq -r '
  (.tool_input.command // "") | (first(scan("\\S+")) // "")
  | if test("=") then "<env-assign>"
    elif test("^[A-Za-z0-9._+/-]*$") then (split("/") | last // "")
    else "<other>" end
  | .[0:64]')

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/permission-denied.log"

# Rotate log if > 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)" -gt 1048576 ]; then
  mv "$LOG_FILE" "$LOG_FILE.old"
fi

printf '[%s] DENY tool=%s cmd=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TOOL_NAME" "${FIRST_WORD:--}" >>"$LOG_FILE"
