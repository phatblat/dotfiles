#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PreCompact
# =============================================================================
# Préserve le contexte Git important avant la compaction.
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

echo '{"systemMessage": "📝 Compacting - Preserving: modified files, branches, pending tasks."}'

if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo 'detached')
    modified=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    echo "Git: branch=$branch, modified_files=$modified" >> "${TMPDIR:-/tmp}/claude-compact-$(date +%Y%m%d).log" 2>/dev/null || true
fi

exit 0