#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreCompact
# =============================================================================
# Préserve le contexte Git important avant la compaction.
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

summary="modified files, branches, pending tasks"
if git rev-parse --git-dir >/dev/null 2>&1; then
    uncommitted=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    branch=$(git branch --show-current 2>/dev/null)
    if [ "$uncommitted" -gt 0 ]; then
        summary="${uncommitted} uncommitted file(s) on ${branch:-detached HEAD}, pending tasks"
    fi
fi

echo "{\"systemMessage\": \"📝 Compacting - Preserving: ${summary}.\"}"

exit 0