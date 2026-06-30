#!/usr/bin/env bash
set -euo pipefail

# Run `just format` before git commit to ensure consistent formatting.
# Only stages files that formatting actually changed — preserves partial staging.
# Uses git hash-object to compare content before/after, handling spaces in paths.

declare -A before_hashes
while IFS= read -r f; do
  [[ -f "$f" ]] && before_hashes["$f"]=$(git hash-object "$f")
done < <(git diff --name-only)

just format 2>&1

staged=0
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  new_hash=$(git hash-object "$f")
  old_hash=${before_hashes["$f"]:-}
  if [[ -z "$old_hash" || "$old_hash" != "$new_hash" ]]; then
    git add -- "$f"
    staged=1
  fi
done < <(git diff --name-only)

if [[ "$staged" -eq 1 ]]; then
  echo '{"systemMessage":"Auto-formatted and staged changed files before commit."}'
fi
