#!/usr/bin/env bash
# Thin PreToolUse adapter for the shared harness write/edit safety policy.
#
# Copyright: Ben Chatelain. Apache 2.0.

set -euo pipefail

trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
content=$(echo "$input" | jq -r '(.tool_input.content // "") + (.tool_input.new_string // "")' 2>/dev/null || echo "")

harness="claude"
case "$0" in
    *".codex/"*) harness="codex" ;;
esac

status=0
result=$(python3 "$HOME/scripts/agent-harnesses.py" guard --harness "$harness" --tool write --path "$file_path" --content "$content" 2>/dev/null) || status=$?
decision=$(printf '%s' "$result" | jq -r '.decision // "deny"')
reason=$(printf '%s' "$result" | jq -r '.reason // "Shared guard failed closed"')

if [ "$decision" = "deny" ]; then
    jq -n --arg reason "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
fi

exit 0
