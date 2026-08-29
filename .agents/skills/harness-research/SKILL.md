---
name: harness-research
description: Research one agent harness's release (docs, source, runtime) and fill its capability cells in scripts/harness_capabilities.py with cited evidence. Use after a harness version bump, when just harness-probe reports re-research, or when capability cells read unknown.
disable-model-invocation: true
---

# harness-research

Turn one harness release into filled-in, cited capability cells. One run
covers one `(harness, version)` pair. The output is an edit to
`scripts/harness_capabilities.py` plus regenerated docs — never a prose
report that rots outside the registry.

## Argument contract

Whitespace-split `$ARGUMENTS`, order-independent:

- A token in `{claude, codex, opencode, pi, omp, antigravity, cursor, grok,
  crush}` selects the harness. Required; if absent, read
  `docs/harness/versions.json` and pick the harness whose `version` differs
  from its `previous`, then say which one you chose.
- A token matching `<domain>` or `<domain>.<name>` narrows the run to those
  capabilities. None given means every cell that reads `unknown`.
- Any other token: stop and print the valid token set. Do not fuzzy-match.

## Hard rules

1. **Primary sources only.** A cell may be filled from that harness's own
   documentation, its own source at the release tag, or its own live
   `--help`/CLI output. Never infer a cell from a sibling harness, from this
   repository's adapters, or from what "should" be true.
2. **Never edit `scripts/agent-harnesses.py`.** It is control plane and
   human-only (`~/.agents/harness/hooks/safety.py`,
   `_CONTROL_PLANE_FRAGMENTS`). Registry edits land in
   `scripts/harness_capabilities.py`; renderer changes in
   `scripts/harness_docs.py`; probe kinds in `scripts/harness_drift.py`. A
   change that truly needs the control-plane module is reported as a
   hand-patch for the user.
3. **First standing target: `hooks.safety` for crush.** Its `next_action`
   still says "Install crush and verify it blocks a denied shell command
   through the generated crushrc PreToolUse hook", but the crush binary is
   now on `PATH`. Verify the live block, then either mark the cell `aligned`
   with `runtime` evidence or record what actually happened.

## Steps

1. **Read what already moved.** `docs/harness/versions.json` for the version
   delta, and `just harness-drift --harness <slug>` for the recorded
   changes. A `field: "version"` record with no capability records means
   nothing was re-verified after that bump.
2. **List the unresearched cells:**
   ```bash
   jq -r '.capabilities[] | select(.cells["<slug>"].parity == "unknown") | .id' \
     docs/agent-harnesses.json
   ```
   Work `p0` first, then `p1`, then `p2`. Read each capability's `contract`
   on its domain page under `docs/harness/` before looking anything up: the
   contract, not the vendor's feature name, is what the cell answers.
3. **Find the primary source.** Prefer the harness's documentation URL, then
   its source permalink pinned to the release tag, then live `--help`. Pin
   permalinks to a tag or commit, never to a branch — the convention in
   `.agents/skills/optimize-harness/references/session-usage-evidence.md` is
   the pattern to copy.
4. **Write the finding into `CAPABILITIES`.** Set `parity`, `mode`,
   `surface`, `note`, and `evidence=Evidence(kind=..., ref=..., version=...,
   date=...)` where `date` is the day you checked it. Add a `probe` whenever
   a deterministic local check exists: `file_exists`, `file_contains`,
   `cli_help_contains`, or `cli_exit_zero`. `parity` in
   `{partial, blocked}` requires a `next_action` naming the next concrete
   step.
5. **Record a permanent difference as a divergence.** When the difference is
   upstream-intentional and will never close, add a `Divergence` with its
   `reason` and `coping`, and set the cell `parity="divergent"` with that
   id — never a `next_action`. A divergence is not owed work.
6. **Verify.** From the repository root, with `HOME` pointed at the
   checkout so the generator reads and writes this tree rather than your
   real home:
   ```bash
   HOME="$PWD" just harness-probe --harness <slug>
   HOME="$PWD" just harness-generate
   HOME="$PWD" just harness-check
   ```
   `harness-check` runs `validate_registry()`, so a cell that violates an
   invariant fails there with the offending `<capability>[<slug>]` named.

## What not to do

- Do not fill a cell to raise coverage. `unknown` with no evidence is
  honest; `aligned` with invented evidence is a lie the ledger will carry
  forward.
- Do not machine-rewrite the registry from probe results. A probe supplies
  evidence and raises drift; the parity verdict is a human-or-agent judgment
  recorded by hand.
- Do not delete a `surface` string to satisfy a rule. Those strings are
  recorded research and predate the parity vocabulary.
- Do not commit `docs/harness/drift.jsonl` records you produced by
  perturbing state to test the pipeline.
