---
name: git-value-scrubbing
description: This skill should be used when the user asks to "scrub JSON values", "mask config fields", "add a Git clean filter", "remove volatile values from tracked config", or "stop config churn".
---

# git-value-scrubbing

Strip volatile or secret values out of a tracked config file's committed blob, while leaving the
real, live file on disk untouched, using this repository's existing git clean-filter convention.

## Purpose and data flow

A git clean filter runs only when git reads the working tree into a blob — on `add`, `status`,
and `diff`. It rewrites what git *stores*, not what's on disk. The `smudge` side of the filter is
always `cat` (identity): git never writes the sentinel/scrubbed values back onto the working-tree
file, so the tool that owns the config (Codex, Pi, `oc`, etc.) keeps reading and writing its real
values normally. This is a one-way clean-only pipeline: live file → filter → committed blob.

## Before editing: inspect the existing convention

Before writing anything, gather:

1. The exact target path and the exact key(s)/field(s) to scrub, including whether they can be
   nested inside arrays/objects rather than only at the top level.
2. `.gitattributes` — existing filter comments and `path filter=<name>` rules. Each filter gets
   its own named entry; never repurpose another filter's name for a different file.
3. `scripts/mask-*.sh` — the existing clean filter scripts. Each one is a `#!/usr/bin/env bash`,
   `set -euo pipefail` script that reads the file on stdin and writes the scrubbed result on
   stdout, with a header comment explaining what churns, why, and the exact wiring block.
4. `justfile`'s `git-filters` recipe — the local-only `git config --local filter.<name>.{clean,smudge,required}`
   registration block, plus its trailing `@echo` install-status line.

Reuse this exact shape. Do not invent a different wiring mechanism, a different recipe name, or a
committed `.git/config` entry — filter registration is local-machine state, not repo state.

## Choosing sentinel vs. deletion

For each field being scrubbed, decide once and document the reasoning in the script's header
comment:

- **Deletion** (`del(.field)` or equivalent) — use when the field is a secret or credential that
  the owning tool does not require to be present at all for correct operation (it falls back to
  an env var, re-authenticates, or treats a missing key as "unset"). Confirm the fallback exists
  before deleting; do not delete a field the tool requires to parse or start.
- **Fixed, type-preserving sentinel** — use when the field is non-secret but high-churn (a cache
  timestamp, an ETag, a revision hash) and the file must still parse cleanly on a fresh checkout.
  Pick a sentinel of the *same JSON/TOML type* as the real value: `0` for a numeric epoch,
  `""` for a string like an ETag, an all-zero hash of the correct length for a hex digest. Never
  swap a sentinel's type (e.g. `null` for a number) if the consuming tool would then fail to parse
  or coerce it.

If a live runtime check shows a chosen sentinel is rejected by the owning tool, switch that one
field to deletion instead of widening the scrub set to fields that don't need it, and re-verify.

## Implementing the filter script

Write `scripts/mask-<name>.sh`:

```bash
#!/usr/bin/env bash
#
# mask-<name>.sh — git "clean" filter for <path>
#
# <what churns, why, and which fields>
#
# This filter runs when git reads the working tree into a blob (add/status/diff)
# and normalizes the volatile VALUES to fixed sentinels/deletes them, so the
# committed content is stable across refreshes and machines. It only rewrites
# what git stores — the on-disk file is never touched.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  <path> filter=<name>
#   git config filter.<name>.clean  ~/scripts/mask-<name>.sh
#   git config filter.<name>.smudge cat
#   git config filter.<name>.required true
#
set -euo pipefail

jq '...'   # or sed -E ... for non-JSON formats
```

For JSON files where the target keys can appear nested (inside arrays of objects, per-entry
maps, etc.), use `jq`'s `walk(...)` with `with_entries(...)` so every nested object is visited —
do not assume the fields only exist at the top level:

```jq
walk(
  if type == "object" then
    with_entries(
      if .key == "<field1>" then
        .value = 0
      elif .key == "<field2>" then
        .value = ""
      else
        .
      end
    )
  else
    .
  end
)
```

For non-JSON formats (TOML, YAML, plain key=value), use targeted `sed -E` substitutions anchored
to the exact key, following `scripts/mask-codex-state.sh`'s pattern. Make the script executable.

## Wiring it in

1. Add a `.gitattributes` entry: a comment block explaining what churns/what's secret, the
   clean-only behavior, that `just git-filters` installs it, and the script path — followed by
   `<path> filter=<name>`. Insert it as its own paragraph; do not merge it into another filter's
   comment block.
2. Extend the `justfile` `git-filters` recipe with three new lines
   (`git config --local filter.<name>.clean`, `.smudge cat`, `.required true`) and one new
   trailing `@echo "Git filter '<name>' installed (...)"` line. Do not create a second recipe.
3. Run `just git-filters` to register the local filter config.
4. Stage **only** the target file with `git add --renormalize -- <path>`. Never run a broad
   `git add -A`, `git add .`, or `git add --renormalize .` in this step — that would renormalize
   and potentially stage every other attributes-governed file, including ones with unrelated
   in-progress user edits. If other files are currently modified in the worktree, they must remain
   exactly as unstaged as they were before this step.

## Verifying

Run all of the following before considering the scrub done:

- `git check-attr filter -- <path>` reports `<name>`.
- `git config --local --get-regexp '^filter\.<name>\.'` reports `clean`, `smudge`, and `required`.
- Pipe the filter script over the live worktree file and assert every scrubbed field matches its
  sentinel/absence with a `jq -e` predicate, e.g.:
  `scripts/mask-<name>.sh < <path> | jq -e '<predicate over .. | objects>'`. In the same step,
  read the raw worktree file directly and confirm it still shows live, non-sentinel values — the
  filter must not have touched disk.
- After `git add --renormalize -- <path>`, assert the index blob *is* the clean output:
  `test "$(git hash-object --path=<path> <path>)" = "$(git rev-parse :'<path>')"`, and re-run the
  same `jq -e` sentinel predicate against `git show :'<path>'`.
- `git diff --name-only --cached` lists only `<path>` — confirm no other file was staged as a side
  effect, and confirm any other in-progress worktree changes remain unstaged
  (`git status --short -- <other-file>` still shows a leading space, not `M `).
- Normalize both the live worktree file and the index blob through the identical filter expression
  into two `mktemp` files and `cmp` them: equal output proves every non-scrubbed byte survived
  renormalization unchanged. Then read `git diff --cached -- <path>` and confirm it contains only
  the scrubbed-field changes plus any pre-existing legitimate edits — nothing else.
- Prove future churn resistance without touching the worktree file: pipe a `jq`/`sed` transform
  that changes the scrubbed fields to different arbitrary live values through the filter script,
  and `cmp`/diff it against the filter's current output on the real file. Identical output proves
  the next real refresh will not change the committed blob.
- If a `skill-reviewer` (or equivalent) agent is available, run it against this file after any
  edits and resolve every finding before delivery.

## Explicit prohibitions

- Never mutate the on-disk config file in place to "pre-scrub" it — the filter must be the only
  thing that ever produces the scrubbed representation, and only inside git's blob pipeline.
- Never give the filter a non-`cat` `smudge` command that would write sentinel/scrubbed values
  back into the working tree — that would corrupt the live config the owning tool depends on.
- Never stage anything broader than the single target path when renormalizing; never let this
  workflow touch or reset unrelated in-progress user edits in other tracked files.
- Never log, echo, or otherwise surface the real secret/volatile values being scrubbed while
  writing or testing the filter script — pipe through commands, don't print intermediate values
  containing live secrets to shared terminal output or committed examples.
