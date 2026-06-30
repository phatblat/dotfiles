#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: SessionEnd
# =============================================================================
# Affiche un résumé à la fin de la session et rappelle les fichiers non committés.
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

echo ''
echo '👋 Claude Code Session Ended'
echo "   $(date '+%Y-%m-%d %H:%M:%S')"

if git rev-parse --git-dir >/dev/null 2>&1; then
    uncommitted=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$uncommitted" -gt 0 ]; then
        echo "   ⚠️ $uncommitted uncommitted file(s)"
    fi
fi

exit 0