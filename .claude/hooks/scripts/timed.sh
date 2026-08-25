#!/usr/bin/env bash
#
# timed.sh — measures and logs the wall-clock duration of one Claude Code
# hook invocation, so a hook-chain latency spike (e.g. a matcher group's p95
# far exceeding its p50) can be attributed to a specific hook script instead
# of only the whole-group aggregate Claude's own session transcript records.
#
# Usage (as a hook "command" in ~/.claude/settings.json):
#   bash ~/.claude/hooks/scripts/timed.sh <hook-name> <event:matcher> '<real command>'
#
# Logs one tab-separated line per invocation to ~/.claude/logs/hook-timing.log:
#   <iso8601 UTC>\t<event:matcher>\t<hook-name>\t<duration_ms>ms\texit=<code>
#
# This wraps the existing command unmodified (bash -c "$3"); it never edits
# the wrapped hook script itself, so control-plane guarded scripts
# (bash-guard.sh, write-guard.sh) stay untouched — only their measured cost
# becomes visible.
#
set -uo pipefail

hook_name=${1:?timed.sh: missing hook-name}
event_name=${2:?timed.sh: missing event:matcher}
real_command=${3:?timed.sh: missing command to run}

log_dir="${HOME}/.claude/logs"
mkdir -p "$log_dir"

start_ns=$(date +%s%N)
bash -c "$real_command"
rc=$?
end_ns=$(date +%s%N)
duration_ms=$(( (end_ns - start_ns) / 1000000 ))

printf '%s\t%s\t%s\t%dms\texit=%d\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$event_name" "$hook_name" "$duration_ms" "$rc" \
  >> "$log_dir/hook-timing.log"

exit "$rc"
