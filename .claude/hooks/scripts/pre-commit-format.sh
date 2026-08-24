#!/usr/bin/env bash
set -euo pipefail

# Run `just format` before git commit to ensure consistent formatting.
# Fires on every Bash PreToolUse — gate on the command first so the repo-wide
# format sweep only pays for itself on actual commit paths (perf: this hook was
# 422 firings, p50 1425ms, p95 10s over 30d without the gate; see 9f7c intent).
input="$(cat)"
if ! command -v jq >/dev/null; then
  # Fail open: a formatter must never block commits when jq is unavailable.
  exit 0
fi
cmd="$(jq -r '.tool_input.command // ""' <<<"$input" || printf ''))"
case "$cmd" in
  *git*commit*) ;; # git commit / git -C repo commit / rtk git commit / git add … && git commit
  *) exit 0 ;;
esac
# Only stages files that formatting actually changed — preserves partial staging.
# Uses git hash-object to compare content before/after, handling spaces in paths.
#
# No `declare -A` here. macOS ships bash 3.2, which has no associative arrays,
# and settings.json invokes this as `bash <script>` rather than through the
# shebang — so a bash 4 builtin makes the hook fail closed and block every
# commit instead of formatting anything. Snapshot lines are "<hash> <path>",
# and a path is recognized as changed when its line is absent from the earlier
# snapshot; git hashes never contain spaces, so paths that do still round-trip.

snapshot() {
  while IFS= read -r f; do
    [[ -f $f ]] && printf '%s %s\n' "$(git hash-object "$f")" "$f"
  done < <(git diff --name-only)
  return 0
}

before="$(snapshot)"

just format 2>&1

staged=0
while IFS= read -r line; do
  [[ -n $line ]] || continue
  if ! printf '%s\n' "$before" | grep -qxF -- "$line"; then
    git add -- "${line#* }"
    staged=1
  fi
done <<<"$(snapshot)"

if [[ $staged -eq 1 ]]; then
  echo '{"systemMessage":"Auto-formatted and staged changed files before commit."}'
fi
