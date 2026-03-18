#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreToolUse - Write/Edit Guard (unified)
# =============================================================================
# Blocks writes to protected files AND detects secrets in written content.
# SANITIZED: Exact secret regex patterns replaced with categories.
# Adapt the patterns below to your threat model.
#
# Input: JSON via stdin with tool_input.file_path, tool_input.content, tool_input.new_string
# Output: JSON with permissionDecision deny if dangerous
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Fail-closed: if anything errors, deny by default
trap 'echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Hook error - fail-closed\"}}"; exit 0' ERR

# Read stdin JSON
input=$(cat)

# === 1. Protected file paths ===
# Block writes to sensitive files (credentials, keys, configs)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

if [ -n "$file_path" ]; then
    # Categories to protect (add your own patterns):
    # - Environment files (.env, .env.production, .env.local)
    # - SSH keys (id_rsa, id_ed25519)
    # - TLS certificates (.pem, .key, .p12, .pfx, .jks)
    # - Cloud credentials (.aws/, .docker/config.json, kubeconfig)
    # - Package registry auth (.npmrc, .pypirc, .netrc)
    # - Database credentials (.pgpass)
    # - HTTP auth (.htpasswd)
    # - Git credentials (.git-credentials)
    #
    # Example:
    # protected_patterns='\.env($|\.)|\.ssh/|\.pem$|\.key$'
    protected_patterns='\.env($|\.)|\.ssh/|id_(rsa|ed25519|ecdsa)|\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|\.aws/credentials|\.docker/config\.json|kubeconfig|\.npmrc$|\.pypirc$|\.netrc$|\.pgpass$|\.htpasswd$|\.git-credentials'

    if [ "$protected_patterns" != "YOUR_PATTERNS_HERE" ]; then
        if echo "$file_path" | grep -qiE "$protected_patterns"; then
            echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Cannot write to protected file: $file_path\"}}"
            exit 0
        fi
    fi
fi

# === 2. Secret detection in content ===
# Scan content being written for hardcoded secrets
content=$(echo "$input" | jq -r '(.tool_input.content // "") + (.tool_input.new_string // "")' 2>/dev/null || echo "")

if [ -n "$content" ]; then
    # Categories of secrets to detect (add regex for each):
    # - AI provider API keys (OpenAI, Anthropic, etc.)
    # - Cloud provider access keys (AWS, GCP, Azure)
    # - VCS tokens (GitHub, GitLab)
    # - Chat platform tokens (Slack, Discord)
    # - Private keys (PEM-encoded)
    # - OAuth tokens
    # - JWT tokens
    # - Payment processor keys (Stripe, etc.)
    # - Email service keys (SendGrid, etc.)
    # - Package registry tokens (npm, PyPI)
    # - Cloud storage keys (Azure, S3)
    # - Database connection strings with embedded passwords
    #
    # TODO: Add your regex patterns matching the prefixes of each provider.
    # See: https://docs.gitguardian.com/secrets-detection/detectors
    secret_patterns='AKIA[0-9A-Z]{16}|sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|glpat-[a-zA-Z0-9_-]{20}|xox[bpoas]-[a-zA-Z0-9-]+|-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|password\s*[:=]\s*["\x27][^"\x27]{8,}'

    if [ "$secret_patterns" != "YOUR_PATTERNS_HERE" ]; then
        if echo "$content" | grep -qE "$secret_patterns"; then
            echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Potential secret/API key detected in content"}}'
            exit 0
        fi
    fi
fi

exit 0
