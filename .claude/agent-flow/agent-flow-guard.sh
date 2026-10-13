#!/usr/bin/env bash
find "$HOME/.claude/agent-flow/" -maxdepth 1 -name "*.json" ! -name "workspaces.json" 2>/dev/null | grep -q . || exit 0
exec mise exec bun -- bun "$HOME/.claude/agent-flow/hook.js"
