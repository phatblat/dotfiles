#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: PostToolUse - Write/Edit Auto-Format
# =============================================================================
# Formate automatiquement les fichiers après écriture.
# Supporte: TypeScript, JavaScript, Python, JSON
# Input: JSON via stdin avec tool_input.file_path
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

format_with_prettier() {
    local target="$1"
    if [ -x "./node_modules/.bin/prettier" ]; then
        ./node_modules/.bin/prettier --write "$target" 2>/dev/null || true
    elif command -v prettier >/dev/null 2>&1; then
        prettier --write "$target" 2>/dev/null || true
    elif command -v npx >/dev/null 2>&1; then
        npx --no-install prettier --write "$target" 2>/dev/null || true
    fi
}

# Lire stdin JSON
input=$(cat)

# Extraire file_path depuis tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")

if [ -n "$file_path" ] && [ -f "$file_path" ]; then
    case "$file_path" in
        *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
            format_with_prettier "$file_path"
            ;;
        *.py)
            if command -v ruff >/dev/null 2>&1; then
                ruff format --quiet "$file_path" 2>/dev/null || true
            elif command -v black >/dev/null 2>&1; then
                black --quiet "$file_path" 2>/dev/null || true
            fi
            ;;
        *.json)
            format_with_prettier "$file_path"
            ;;
    esac
fi

exit 0