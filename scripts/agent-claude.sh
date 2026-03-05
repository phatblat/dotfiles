#!/usr/bin/env bash
# agent-claude.sh - Wrapper that runs claude with a scoped-down GitHub token
#
# Used by Gas Town agent sessions to limit gh CLI permissions.
# The token file must exist and contain a fine-grained PAT with:
#   - Contents: Read & Write (push topic branches)
#   - Pull requests: Read & Write (create/update PRs, comment, draft toggle)
#   - Actions: Read & Write (re-run failed CI jobs)
#   - Metadata: Read (auto-granted)
#
# Token file: ~/.config/gastown/agent-gh-token
# Create at: https://github.com/settings/personal-access-tokens/new

set -euo pipefail

TOKEN_FILE="${HOME}/.config/gastown/agent-gh-token"

if [[ -f "$TOKEN_FILE" ]]; then
    export GH_TOKEN
    GH_TOKEN="$(cat "$TOKEN_FILE")"
else
    echo "WARNING: agent-gh-token not found at $TOKEN_FILE" >&2
    echo "Agents will use default gh auth (full permissions)" >&2
fi

exec claude "$@"
