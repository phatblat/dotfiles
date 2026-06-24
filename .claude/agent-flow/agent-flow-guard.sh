#!/usr/bin/env bash
ls "$HOME/.claude/agent-flow/"*.json 2>/dev/null | grep -q . || exit 0
exec mise exec bun -- bun "$HOME/.claude/agent-flow/hook.js"
