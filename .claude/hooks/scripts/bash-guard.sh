#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Bash Guard (unified)
# =============================================================================
# Blocks dangerous bash commands (fail-closed) AND warns on commits to the
# protected main/master branch (does not block; skipped for the dotfiles repo
# and repos with <100 commits). Parses stdin once.
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
# eval with vars, base64 decode piped to shell, awk system() calls,
# bash process substitution.
# Note: sed execute-flag detection was removed — the pattern cannot
# reliably distinguish `sed 's/x/y/e'` from sed references in commit
# message text, causing false positives on `git commit -m "...sed..."`.
obfuscation_patterns='eval\s+.*\$|base64\s+-d.*\|\s*(ba)?sh|awk\s+.*system\s*\(|bash\s+<\('

if echo "$command" | grep -qE "$obfuscation_patterns"; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Obfuscated execution pattern detected"}}'
    exit 0
fi

# === 4. Main-branch commit warning (does NOT block) ===
# Only inspect git commit commands; warn so Claude self-corrects.
# Exceptions (no warning): the dotfiles repo (root == $HOME) and young repos
# (<100 commits), where branch ceremony adds no value. Mirrors /git:commit.
if echo "$command" | grep -qE '^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)'; then
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
        commit_count=$(git rev-list --count HEAD 2>/dev/null || echo 0)
        if [ "$repo_root" != "${HOME:-}" ] && [ "$commit_count" -ge 100 ]; then
            printf '{"systemMessage":"WARNING: You are on the protected '\''%s'\'' branch. Commits will be rejected on push. Create a feature branch first: git checkout -b <type>/<short-description>."}\n' \
                "$current_branch"
        fi
        exit 0
    fi
fi

exit 0
