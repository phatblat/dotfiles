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
# Pattern 1: keywords that strongly imply secrets
has_strong_keyword=$(echo "$prompt" | grep -ciE '(mot de passe|password|api.?key|credential)' || true)
# Pattern 2: "token" or "secret" only when followed by assignment-like syntax (=, :, "is")
has_assignment=$(echo "$prompt" | grep -ciE '(token|secret)\s*[:=]|(token|secret)\s+is\s+\S' || true)
# Pattern 3: actual secret-looking values (long random strings, known prefixes)
has_secret_value=$(echo "$prompt" | grep -cE '(ghp_|gho_|sk-|xoxb-|xoxp-|AKIA)[A-Za-z0-9]{10,}' || true)

if [[ "$has_strong_keyword" -gt 0 || "$has_assignment" -gt 0 || "$has_secret_value" -gt 0 ]]; then
    if ! echo "$prompt" | grep -qiE '(comment|how|aide|help|expliqu|what is|qu.est)'; then
        echo '{"systemMessage":"⚠️ Warning: your prompt mentions sensitive information. Never share real secrets in the chat."}'
    fi
fi

exit 0