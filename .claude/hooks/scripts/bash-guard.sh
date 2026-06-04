#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Bash Guard (unified)
# =============================================================================
# Blocks dangerous bash commands (fail-closed) AND warns on commits to the
# protected main/master branch (does not block). Parses stdin once.
# Replaces the former bash-guard.sh + main-branch-guard.sh pair.
#
# Input: JSON via stdin with tool_input.command
# Output: JSON permissionDecision deny (dangerous) OR systemMessage (warning)
#
# Copyright: Delanoe Pirard / Aedelon (dangerous-command checks),
#            Ben Chatelain (main-branch warning). Apache 2.0
# =============================================================================

set -euo pipefail

# Fail-closed: if anything errors during the security checks, deny by default
trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

# Read stdin JSON once
input=$(cat)

# Extract command from tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# === 1. Privilege escalation (block, not just warn) ===
# Catches: sudo, su, doas, pkexec — at start of command or after ; && || $( `
if echo "$command" | grep -qE '(^|;|&&|\|\||\$\(|`)\s*(sudo|su |doas |pkexec)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Privilege escalation blocked."}}'
    exit 0
fi

# === 2. Destructive patterns ===
# Recursive force delete, device writes, permission bombs, fork bombs,
# pipe-to-shell, data destruction.
dangerous_patterns='rm\s+-rf\s+(/|~|\*|\.\.)|>\s*/dev/sd|mkfs\s|dd\s+if=.*of=/dev|chmod\s+(-R\s+)?777|chmod\s+\+s|:\(\)\{.*:\|:&\}\;|curl[^|]*\|\s*(ba)?sh|wget[^|]*\|\s*(ba)?sh|truncate\s|shred\s'

if echo "$command" | grep -qE "$dangerous_patterns"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dangerous command pattern detected"}}'
    exit 0
fi

# === 3. Indirect execution / obfuscation ===
# eval with vars, base64 decode piped to shell, sed execute flag,
# awk system() calls, bash process substitution.
obfuscation_patterns='eval\s+.*\$|base64\s+-d.*\|\s*(ba)?sh|(^|[\s;|&])sed\s+.*e\s|awk\s+.*system\s*\(|bash\s+<\('

if echo "$command" | grep -qE "$obfuscation_patterns"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Obfuscated execution pattern detected"}}'
    exit 0
fi

# === 4. Main-branch commit warning (does NOT block) ===
# Only inspect git commit commands; warn so Claude self-corrects.
if echo "$command" | grep -qE '^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)'; then
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        today=$(date +%A | tr '[:upper:]' '[:lower:]')
        printf '{"systemMessage":"WARNING: You are on the '\''%s'\'' branch, which is protected. Commits will be rejected on push. Switch to today'\''s daily branch with: git checkout %s — or run /daily to set up the daily workflow."}\n' \
            "$current_branch" "$today"
        exit 0
    fi
fi

exit 0
