#!/usr/bin/env bash
set -euo pipefail

# Run `just format` before git commit to ensure consistent formatting.
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
