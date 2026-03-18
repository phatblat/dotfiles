#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PermissionRequest - Git Operations
# =============================================================================
# Avertit pour les operations Git potentiellement destructives.
# Input: JSON via stdin avec tool_input.command
# Output: JSON {"systemMessage": "..."} pour avertir
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Lire stdin JSON
input=$(cat)

# Extraire command depuis tool_input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

[ -z "$command" ] && exit 0

# Patterns destructifs Git
if echo "$command" | grep -qE 'git (push --force|push -f|reset --hard|clean -f|checkout -- \.|restore \.|branch -D|stash drop|stash clear|rebase)'; then
    echo '{"systemMessage":"Potentially destructive Git operation. Verify branch and uncommitted changes."}'
fi

exit 0
