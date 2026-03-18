#!/usr/bin/env bash
# PostToolUseFailure — Log tool failures for debugging
# Receives tool_name, error via stdin JSON

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // .stderr // "no details"' | head -c 500)

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/tool-failures.log"

# Rotate log if > 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)" -gt 1048576 ]; then
  mv "$LOG_FILE" "$LOG_FILE.old"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] FAIL tool=$TOOL_NAME error=$(echo "$ERROR" | tr '\n' ' ' | head -c 200)" >> "$LOG_FILE"
