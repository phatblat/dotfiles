#!/usr/bin/env bash
set -euo pipefail

# Run `just format` before git commit — but only in the repository the command
# actually targets, never the hook's own checkout.
#
# Fires on every Bash PreToolUse — gate on the command first so the repo-wide
# format sweep only pays for itself on actual commit paths.
input="$(cat)"
if ! command -v jq >/dev/null; then
  # Fail open: a formatter must never block commits when jq is unavailable.
  exit 0
fi
cmd="$(jq -r '.tool_input.command // ""' <<<"$input" || printf '')"
payload_cwd="$(jq -r '.cwd // ""' <<<"$input" || printf '')"
[ -n "$payload_cwd" ] || payload_cwd="$PWD"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(realpath "$script_dir")"
target="$(python3 "$script_dir/commit_target.py" "$cmd" "$payload_cwd")" || target=""
[ -n "$target" ] || exit 0

# Only stages files that formatting actually changed — preserves partial staging.
# Uses git hash-object to compare content before/after, handling spaces in paths.
#
# No `declare -A` here. macOS ships bash 3.2, which has no associative arrays,
# and settings.json invokes this as `bash <script>` rather than through the
# shebang — so a bash 4 builtin makes the hook fail closed and block every
# commit instead of formatting anything. Snapshot lines are "<path> <hash>",
# and a path is recognized as changed when its line is absent from the earlier
# snapshot; git hashes never contain spaces, so paths that do still round-trip.

repo_root="$(git -C "$target" rev-parse --show-toplevel 2>/dev/null || printf '')"
[ -n "$repo_root" ] || exit 0
[ -f "$repo_root/justfile" ] || exit 0

snapshot() {
  local root="$1"
  git -C "$root" diff --name-only | while IFS= read -r f; do
    [[ -f "$root/$f" ]] && printf '%s %s\n' "$f" "$(git -C "$root" hash-object "$root/$f")"
  done
  return 0
}

before="$(snapshot "$repo_root")"

just --justfile "$repo_root/justfile" format 2>&1

staged=0
while IFS= read -r line; do
  [[ -n $line ]] || continue
  path="${line%% *}"
  if ! printf '%s\n' "$before" | grep -qxF -- "$line"; then
    git -C "$repo_root" add -- "$path"
    staged=1
  fi
done <<<"$(snapshot "$repo_root")"

if [[ $staged -eq 1 ]]; then
  if [[ -f "$HOME/scripts/flywheel-record.py" ]]; then
    python3 "$HOME/scripts/flywheel-record.py" scaffold \
      --scaffold claude-pre-commit-format \
      --harness claude \
      --detail "staged=1" >/dev/null 2>&1 || true
  fi
  echo '{"systemMessage":"Auto-formatted and staged changed files before commit."}'
fi
