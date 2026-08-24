#!/usr/bin/env bash
# Thin PreToolUse adapter for the shared harness bash safety policy.
#
# Copyright: Ben Chatelain. Apache 2.0.

set -euo pipefail

trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# Fast-path: skip the Python guard spawn for simple, read-only utilities that
# have no shell composition or write-capable flags. This is a performance
# pre-filter only; anything complex still falls through to the shared guard.
_is_simple_command() {
    # Reject command separators, pipes, redirections, and command substitution.
    [[ "$1" =~ [\;\&\|\<\>\`] ]] && return 1
    [[ "$1" == *'$('* ]] && return 1
    return 0
}

_is_safe_readonly() {
    local cmd="$1"
    # Strip leading whitespace.
    cmd="${cmd#"${cmd%%[![:space:]]*}"}"
    [[ "$cmd" =~ ^(echo|wc|head|tail|grep|cat|ls|ps|date|which|pwd|env|true|false|jq|sort|uniq|tr|cut|file|stat|cmp|diff|du|tty|uname|hostname|whoami|nproc|printf|seq|basename|dirname|readlink|realpath|printenv|command[[:space:]]+-v)([[:space:]]|$) ]]
}

if _is_simple_command "$command" && _is_safe_readonly "$command"; then
    exit 0
fi

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
