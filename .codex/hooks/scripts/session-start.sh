#!/usr/bin/env bash
# =============================================================================
# Codex Hook: SessionStart
# =============================================================================
# Injects project information into the Codex session context.
# Input: JSON via stdin avec session_id, cwd, source, etc.
# Output: JSON avec additionalContext
#
# Copyright: Delanoe Pirard / Aedelon. Apache 2.0
# =============================================================================

set -euo pipefail

# Read stdin JSON.
input=$(cat)

# Extract cwd from stdin or use the current directory.
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null || pwd)
cd "$cwd" 2>/dev/null || true

# Build context message
context="🚀 Session started $(date '+%Y-%m-%d %H:%M:%S')"

# Detect project type.
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

# Git information.
if git rev-parse --git-dir >/dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null || echo 'detached')
    changes=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
    if [ "$changes" -gt 0 ]; then
        context="$context | 🌿 $branch ($changes uncommitted)"
    else
        context="$context | 🌿 $branch"
    fi
fi

context="$context | 💡 Codex skills and hooks available"

# Output valid JSON.
# Use jq for safe JSON string encoding to prevent shell injection via project metadata
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":%s}}\n' \
  "$(printf '%s' "$context" | jq -Rs '.')"

exit 0
