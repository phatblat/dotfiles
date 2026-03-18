#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PostToolUse - Bash Vulnerability Detection
# =============================================================================
# Détecte les vulnérabilités après npm/yarn/pnpm install.
# Input: JSON via stdin avec tool_input.command et stdout
# Output: JSON {"systemMessage": "..."} si vulnérabilités détectées
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Lire stdin JSON
input=$(cat)

# Extraire command et stdout depuis l'input
command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
stdout=$(echo "$input" | jq -r '.tool_response // .stdout // empty' 2>/dev/null || echo "")

if echo "$command" | grep -qE '^(npm|pnpm|yarn) (install|add|remove)'; then
    if echo "$stdout" | grep -qiE '(vulnerabilit|CVE-)'; then
        echo '{"systemMessage":"⚠️ Vulnerabilities detected. Run npm audit for details."}'
    fi
fi

exit 0