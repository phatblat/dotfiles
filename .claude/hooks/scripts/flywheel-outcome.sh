#!/usr/bin/env bash
# SessionEnd / StopFailure hook: append a flywheel outcome record to
# ~/.local/state/flywheel/dotfiles/outcomes.jsonl (outside git).
# Usage: flywheel-outcome.sh <success|failed>
# SessionEnd records `success` (the session ended normally); StopFailure records
# `failed`. flywheel-report.py keeps the worst outcome per session.
# Copyright: Ben Chatelain. MIT

set -euo pipefail

outcome="${1:?usage: flywheel-outcome.sh <success|failed>}"
recorder="$HOME/scripts/flywheel-record.py"
[ -f "$recorder" ] || exit 0

python3 "$recorder" outcome \
    --harness claude \
    --outcome "$outcome" \
    --task "claude session ($(basename "$PWD"))" \
    --from-hook-stdin >/dev/null 2>&1 || true

exit 0
