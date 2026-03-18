#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: UserPromptSubmit - Secret Detection
# =============================================================================
# Avertit si le prompt contient des mentions de secrets.
# Input: JSON via stdin avec prompt
# Output: JSON {"systemMessage": "..."} pour avertir
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Lire stdin JSON
input=$(cat)

# Extraire prompt depuis l'input
prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null || echo "")

# Détecte les mentions de secrets (mais pas les questions sur les secrets)
if echo "$prompt" | grep -qiE '(mot de passe|password|api.?key|secret|token|credential)'; then
    if ! echo "$prompt" | grep -qiE '(comment|how|aide|help|expliqu|what is|qu.est)'; then
        echo '{"systemMessage":"⚠️ Warning: your prompt mentions sensitive information. Never share real secrets in the chat."}'
    fi
fi

exit 0