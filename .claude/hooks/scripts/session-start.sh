#!/usr/bin/env bash
# =============================================================================
# Claude Code Hook: SessionStart
# =============================================================================
# Injecte les informations du projet dans le contexte de Claude.
# Input: JSON via stdin avec session_id, cwd, source, etc.
# Output: JSON avec additionalContext
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Lire stdin JSON (obligatoire pour Claude Code)
input=$(cat)

# Extraire le répertoire de travail depuis stdin ou utiliser le cwd actuel
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null || pwd)
cd "$cwd" 2>/dev/null || true

# Build context message
context="🚀 Session started $(date '+%Y-%m-%d %H:%M:%S')"

# Détection du type de projet
if [ -f package.json ]; then
    name=$(jq -r '.name // "project"' package.json 2>/dev/null || echo "project")
    if jq -e '.dependencies.next // .devDependencies.next' package.json >/dev/null 2>&1; then
        context="$context | 📦 $name (Next.js)"
    elif jq -e '.dependencies["react-native"] // .dependencies.expo' package.json >/dev/null 2>&1; then
        context="$context | 📱 $name (React Native)"
    else
        context="$context | 📦 $name (Node.js)"
    fi
elif [ -f pyproject.toml ]; then
    name=$(grep '^name' pyproject.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "project")
    context="$context | 🐍 ${name:-project} (Python)"
elif [ -f Cargo.toml ]; then
    name=$(grep '^name' Cargo.toml 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/' || echo "project")
    context="$context | 🦀 ${name:-project} (Rust)"
elif [ -f go.mod ]; then
    context="$context | 🐹 Go project"
fi

# Informations Git
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo 'detached')
    changes=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$changes" -gt 0 ]; then
        context="$context | 🌿 $branch ($changes uncommitted)"
    else
        context="$context | 🌿 $branch"
    fi
fi

# Liste des commandes disponibles
if [ -d "$HOME/.claude/commands" ]; then
    cmds=$(ls "$HOME/.claude/commands/"*.md 2>/dev/null | xargs -I {} basename {} .md | sort | tr '\n' ' ' || echo "")
    if [ -n "$cmds" ]; then
        context="$context | 📋 Commands: $cmds"
    fi
fi

context="$context | 💡 Skills and agents available"

# Output JSON valide
# Escape special characters for JSON
escaped_context=$(echo "$context" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr '\n' ' ')

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$escaped_context\"}}"

exit 0