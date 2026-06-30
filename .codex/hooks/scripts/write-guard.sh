#!/usr/bin/env bash
# Thin PreToolUse adapter for the shared harness write/edit safety policy.
#
# Copyright: Ben Chatelain. Apache 2.0.

set -euo pipefail

trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

script_dir=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=apply-patch-input.sh
# shellcheck disable=SC1091
source "$script_dir/apply-patch-input.sh"

input=$(cat)

harness="claude"
case "$0" in
    *".codex/"*) harness="codex" ;;
esac

deny() {
    local reason="$1"
    jq -n --arg reason "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
    exit 0
}

evaluate_write() {
    local file_path="$1"
    local content="$2"
    local result
    local decision
    local reason

    result=$(python3 "$HOME/scripts/agent-harnesses.py" guard --harness "$harness" --tool write --path "$file_path" --content "$content" 2>/dev/null || true)
    decision=$(printf '%s' "$result" | jq -r '.decision // "deny"')
    reason=$(printf '%s' "$result" | jq -r '.reason // "Shared guard failed closed"')

    if [ "$decision" = "deny" ]; then
        deny "$reason"
    fi
}

tool_name=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null || echo "")
command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

if [ "$tool_name" = "apply_patch" ] || [[ "$command" == "*** Begin Patch"* ]]; then
    while IFS= read -r path; do
        [ -n "$path" ] && evaluate_write "$path" ""
    done < <(printf '%s' "$input" | apply_patch_all_paths)

    added_content=$(printf '%s' "$input" | apply_patch_added_content)
    evaluate_write "" "$added_content"
else
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null || echo "")
    content=$(printf '%s' "$input" | jq -r '(.tool_input.content // "") + (.tool_input.new_string // "")' 2>/dev/null || echo "")
    evaluate_write "$file_path" "$content"
fi

exit 0
