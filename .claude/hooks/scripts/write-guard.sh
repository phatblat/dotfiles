#!/usr/bin/env bash
# Thin PreToolUse adapter for write/edit calls: hands the payload to the
# compiled harness guard (crates/ness, installed by `just ness-install`).
# Fails closed when it is missing.
#
# Copyright: Ben Chatelain. Apache 2.0.

set -euo pipefail

deny() {
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
    exit 0
}
trap 'deny "Hook error - fail-closed"' ERR

harness="claude"
case "$0" in
    *".codex/"*) harness="codex" ;;
esac

ness="$HOME/.local/bin/ness"
[ -x "$ness" ] || deny "Shared guard failed closed: $ness is not installed (run: just ness-install)"
exec "$ness" hook --harness "$harness" --tool write
