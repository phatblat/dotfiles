#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Main Branch Guard
# =============================================================================
# Warns when git commit is attempted on the main branch.
# Does NOT block — injects a warning message so Claude self-corrects.
#
# Input: JSON via stdin with tool_input.command
# Output: JSON with systemMessage warning (or silent exit for no-op)
#
# Copyright: Ben Chatelain. Apache 2.0
# =============================================================================

set -euo pipefail

input=$(cat)

# Extract command
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# Only care about git commit commands
echo "$command" | grep -qE '^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)' || exit 0

# Check current branch
current_branch=$(git branch --show-current 2>/dev/null || echo "")

# If on main or master, warn
if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
    today=$(date +%A | tr '[:upper:]' '[:lower:]')
    printf '{"systemMessage":"WARNING: You are on the '\''%s'\'' branch, which is protected. Commits will be rejected on push. Switch to today'\''s daily branch with: git checkout %s — or run /daily to set up the daily workflow."}\n' \
        "$current_branch" "$today"
    exit 0
fi

exit 0
