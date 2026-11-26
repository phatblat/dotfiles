#!/usr/bin/env bash
# PermissionDenied — record which tool and command family auto mode refused,
# so optimize-harness can measure missing-allow-rule friction. Logs the tool
# name and the first command word only; never arguments or env assignments.

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"')
FIRST_WORD=$(printf '%s' "$INPUT" | jq -r '
  (.tool_input.command // "") | (first(scan("\\S+")) // "")
  | if test("=") then "<env-assign>" else (split("/") | last // "") end' | head -c 64)

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/permission-denied.log"

# Rotate log if > 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)" -gt 1048576 ]; then
  mv "$LOG_FILE" "$LOG_FILE.old"
fi

printf '[%s] DENY tool=%s cmd=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$TOOL_NAME" "${FIRST_WORD:--}" >>"$LOG_FILE"
