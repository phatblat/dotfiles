#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Bash Guard
# =============================================================================
# Blocks dangerous bash commands before execution.
# SANITIZED: Exact regex patterns replaced with categories.
# Adapt the patterns below to your threat model.
#
# Input: JSON via stdin with tool_input.command
# Output: JSON with permissionDecision deny if dangerous
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Fail-closed: if anything errors, deny by default
trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

# Read stdin JSON
input=$(cat)

# Extract command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# === 1. Privilege escalation (block, not just warn) ===
# Catches: sudo, su, doas, pkexec — at start of command or after ; && || $( `
# TODO: Add your own patterns here
if echo "$command" | grep -qE '(^|;|&&|\|\||\$\(|`)\s*(sudo|su |doas |pkexec)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Privilege escalation blocked."}}'
    exit 0
fi

# === 2. Destructive patterns ===
# Categories to detect (add your regex for each):
# - Recursive force delete (rm -rf /, rm -rf ~, rm -rf *)
# - Device writes (> /dev/sd, mkfs, dd if=...of=/dev)
# - Permission bombs (chmod -R 777, chmod +s)
# - Fork bombs (:(){:|:&};:)
# - Pipe to shell (curl|sh, wget|bash)
# - Data destruction (truncate, shred)
#
# Example:
# dangerous_patterns='rm -rf /|rm -rf ~|:(){ :|:& };:|curl.*\| *sh'
dangerous_patterns='YOUR_PATTERNS_HERE'

if [ "$dangerous_patterns" != "YOUR_PATTERNS_HERE" ]; then
    if echo "$command" | grep -qE "$dangerous_patterns"; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dangerous command pattern detected"}}'
        exit 0
    fi
fi

# === 3. Indirect execution / obfuscation ===
# Categories to detect:
# - eval with variables (eval $var)
# - base64 decode piped to shell
# - sed with execute flag
# - awk system() calls
# - bash process substitution (bash <(...))
#
# Example:
# obfuscation_patterns='eval .*\$|base64 -d.*\|.*(sh|bash)'
obfuscation_patterns='YOUR_PATTERNS_HERE'

if [ "$obfuscation_patterns" != "YOUR_PATTERNS_HERE" ]; then
    if echo "$command" | grep -qE "$obfuscation_patterns"; then
        echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Obfuscated execution pattern detected"}}'
        exit 0
    fi
fi

exit 0
