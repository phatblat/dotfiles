#!/usr/bin/env bash
# Thin PreToolUse adapter for the shared harness bash safety policy.
#
# Copyright: Ben Chatelain. Apache 2.0.

set -euo pipefail

trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

harness="claude"
case "$0" in
    *".codex/"*) harness="codex" ;;
esac

status=0
result=$(python3 "$HOME/scripts/agent-harnesses.py" guard --harness "$harness" --tool bash --command "$command" 2>/dev/null) || status=$?
decision=$(printf '%s' "$result" | jq -r '.decision // "deny"')
reason=$(printf '%s' "$result" | jq -r '.reason // "Shared guard failed closed"')

case "$decision" in
    deny)
        jq -n --arg reason "$reason" '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
          }
        }'
        ;;
    warn)
        jq -n --arg reason "$reason" '{systemMessage: $reason}'
        ;;
esac

exit 0
