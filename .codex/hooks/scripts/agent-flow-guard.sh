#!/usr/bin/env bash
# Codex Agent Flow hook guard.
#
# Uses $CODEX_HOME/agent-flow for live Agent Flow state. If legacy Claude state
# files exist and the Codex state directory is empty, migrate them once.

set -euo pipefail

codex_home="${CODEX_HOME:-$HOME/.codex}"
agent_flow_dir="${AGENT_FLOW_DIR:-$codex_home/agent-flow}"
legacy_agent_flow_dir="${LEGACY_AGENT_FLOW_DIR:-$HOME/.claude/agent-flow}"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
hook_js="${AGENT_FLOW_HOOK_JS:-$script_dir/agent-flow-hook.js}"

mkdir -p "$agent_flow_dir" 2>/dev/null || true

if [ -d "$legacy_agent_flow_dir" ]; then
    while IFS= read -r legacy_state; do
        state_name=$(basename "$legacy_state")
        [ -e "$agent_flow_dir/$state_name" ] || mv "$legacy_state" "$agent_flow_dir/$state_name" 2>/dev/null || true
    done < <(find "$legacy_agent_flow_dir" -maxdepth 1 -name "*.json" ! -name "workspaces.json" 2>/dev/null)
fi

find "$agent_flow_dir" -maxdepth 1 -name "*.json" ! -name "workspaces.json" 2>/dev/null | grep -q . || exit 0
[ -f "$hook_js" ] || exit 0

exec mise exec bun -- bun "$hook_js"
