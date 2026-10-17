# Move the ness safety policy out of code into a TOML file

## Issue

Every rule the guard enforces is a table in code: the regex statics in
`crates/ness/src/policy.rs` (`CONTROL_PLANE_FRAGMENTS`, `PROTECTED_PATHS`,
`SECRET_CONTENT`, `DANGEROUS_COMMANDS`, `INTERACTIVE_LAUNCH`, and the rest) and
the approval baselines in `scripts/harness_policy.py` (`BASH_ALLOW_PREFIX`,
`BASH_ASK_PREFIX`, `BASH_DENY_PREFIX`, the per-harness modes). Both files are
control plane, so the guard denies agent edits to them. That is the right
boundary: no sequence of agent tool calls may change what the guard permits.

The cost lands on the human. A one-line policy change such as "allow `rm` under
`/tmp` without a prompt" means hand-editing a Rust regex table, a JSON corpus
case, and a Python tuple, rebuilding, `just ness-install`, and committing. The
agent can only describe the change in chat. In the 2026-10-17 session the
`/tmp` carve-out was instead hand-written into `~/.omp/agent/config.yml`, where
the next `just harness-perms-apply` overwrites it, and opencode never got it.
The review surface is three languages for a decision that is a list entry.

This decision keeps the boundary and changes the review surface: the policy
becomes data the agent can draft and test, and the human's part becomes one
decision per change.

This decision extends
[2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md):
the engine extraction proceeds as written there; this record moves the data
the engine reads.

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- The security property is unchanged: an agent must not be able to change the
  active policy. The policy file is therefore control plane, the engine refuses
  a policy that does not protect its own inputs, and the only write path is a
  command the guard denies to agents and a human runs from a terminal.
- The guard fails closed on a missing or malformed policy, the opposite of
  `generated-paths.json` (`manifest.rs:14-17`), because a guard with no rules
  is a guard that allows everything.
- Hook latency budget: Claude Code hook runs measure 95 to 113 ms p50
  (`just harness-sessions`). Parsing one TOML file and compiling about forty
  regexes with the `regex` crate adds single-digit milliseconds; the
  implementation measures this and the Decision is revised if it exceeds 10 ms
  p50.
- Current corpus: 127 guard cases in `crates/ness/tests/corpus/*.json` and 29
  shim-conformance cases in `tests/hook_corpus/`. All pass against the compiled
  tables today, so they are the equivalence oracle for the transcription.
- The policy is personal configuration and this repository is `$HOME`, so
  `~/.config/ness/policy.toml` is tracked here and reaches other machines the
  way every other dotfile does.
- `tomllib` is in Python's standard library (3.11+); `toml` + `serde` are
  available to the crate.
- The GitHub-PR-merge gate (0.x + Renovate in the extraction decision) depends
  on the agent's `gh` token not being able to edit branch protection. ness does
  not deny `gh api` writes today. A local gate does not have that dependency.

## Argument

Put every policy table in one TOML file that both ness and
`harness_policy.py` read, with `ness policy check` and `ness policy apply` as
the proposal workflow. **Chosen.** One review surface, one human action per
change, and the control-plane boundary is the same mechanism as today.

Keep regexes in Rust and move only the lists. **Rejected**: two homes for policy
for an indefinite period, and the regex tables are exactly the ones a human
cannot review in Rust source.

Ship the policy as a release asset of the ness repository with PR merge as the
gate. **Deferred** to a Backlog item: the right shape for policy shared beyond
one user is an adoptable standard, and that is a different problem from this
one.

Bring the policy in from another checkout through a filesystem overlay or a
submodule. **Rejected**: see Positions.

## Architectural Decision

1. **One policy file.** `~/.config/ness/policy.toml`, tracked at
   `.config/ness/policy.toml`. Tables, each a list of strings or a small
   struct, with a comment per entry where the reason is not obvious:

   ```toml
   [control_plane]      # paths the guard denies agent writes to; includes this file
   [protected_paths]    # secrets on disk
   [secret_content]     # patterns in written content
   [commands.deny]      # privilege_escalation, dangerous, obfuscated, credential_disclosure
   [commands.interactive_launch]
   [commands.warn]      # main-branch commit warning and similar
   [approval]           # bash allow_prefix, allow_exact, prompt_prefix, deny_prefix
   [approval.modes]     # per-harness default posture (claude, omp, opencode)
   [approval.rm]        # roots under which `rm [flags] <one path>` is allowed
   ```

   Every pattern is a TOML literal string (`'...'`) holding a `regex`-crate
   expression, inline flags included (`(?i)`), compiled at load. Named capture
   groups the engine depends on (`span`) are part of the schema and `check`
   rejects a pattern that drops one.
2. **Loading and fail-closed.** ness loads the file on every invocation from
   that fixed path. There is no flag or environment variable to point it
   elsewhere: an override seam is an agent-reachable way to swap the policy.
   A missing, unparseable, or uncompilable policy makes every `guard` and
   `hook` verdict `deny` with a reason naming the path and
   `ness policy check`.
3. **Floor the policy cannot remove.** The engine keeps one hardcoded table,
   `REQUIRED_PROTECTION`: the policy path, `~/.local/bin/ness`, and the
   command `ness policy apply`. `check` rejects, and `apply` refuses, a
   candidate whose `[control_plane]` and `[commands.deny]` do not cover them.
   Everything else is data.
4. **Corpus as data.** The 127 guard cases move verbatim to
   `~/.config/ness/cases/*.json`, tracked, in their current JSON shape. The
   directory is **not** control plane: an agent writing or deleting a case
   cannot weaken the guard, and `check` reports the case-set delta so a
   deletion is visible. The crate keeps a fixture policy and a handful of
   fixture cases for engine unit tests; the 29 `hook_corpus` shim cases stay in
   the crate per clause 4 of the extraction decision.
5. **`ness policy check <candidate>`.** Exit 0 or 1. Reports, in order: schema
   and regex compile errors; `REQUIRED_PROTECTION` invariants; every case in
   `cases/` run against the candidate, with failures; the **verdict diff**: each
   case whose decision or reason differs between the active policy and the
   candidate; and the case-set delta (added, removed, changed) since the last
   `apply`. The verdict diff is the artifact the human reads.
6. **`ness policy apply <candidate>`.** Runs `check`; refuses on exit 1;
   replaces the active file by atomic rename; records the policy sha256, the
   case-set hash, and a timestamp in `~/.local/state/ness/applied.json`.
   `[commands.deny]` lists `ness policy apply` and clause 3 keeps it there, so
   the guard denies the command when an agent issues it through any harness;
   a human runs it from a terminal.
7. **`ness policy active`.** The default for a bare `ness policy`: prints the
   active path, sha256, applied timestamp, and the entry count per table.
8. **Proposals.** An agent writes a full candidate file to
   `~/.local/state/ness/proposals/<slug>/policy.toml` (untracked, not control
   plane), adds cases to `cases/`, runs `check`, and reports the verdict diff.
   Nothing under `~/.config/ness/` other than `policy.toml` is denied to
   agents.
9. **`harness_policy.py` becomes a transform.** The `BASH_*`, mode, and
   webfetch tuples are deleted; `bash_rules(style)` reads `[approval]` from the
   policy file with `tomllib` and renders it per harness exactly as today.
   `[approval.rm]` renders to omp as the ordered prompt-then-allow glob set
   and to opencode as `"rm <root>/*": "allow"` after `"rm *": "ask"` (opencode
   resolves last match). `harness-apply.py perms` and
   `scripts/agent-harnesses.py` keep their interfaces. The file stays control
   plane: it is the renderer the generated permission files trust.
10. **Shims unchanged.** Every hook still execs `~/.local/bin/ness` by absolute
    path. The fail-closed remedy text gains the policy path.
11. **Acceptance.** The initial `policy.toml` is a transcription of the compiled
    tables. It is accepted when `ness policy check` passes all 127 migrated
    cases with an empty verdict diff against the pre-change binary, the 29
    `hook_corpus` cases pass, `just harness-check` is green with the generated
    permission files unchanged except for the `rm` roots, and the latency
    measurement in Assumptions holds.

## Consequences

- A policy change becomes: agent drafts candidate and cases, runs `check`,
  reports the verdict diff; human reads it and runs `ness policy apply`, then
  commits `.config/ness/`. The Rust engine changes only when a new *kind* of
  rule appears.
- The `/tmp` rules hand-written into `~/.omp/agent/config.yml` on 2026-10-17
  are replaced by generated output from `[approval.rm]`.
- The control-plane list in `.agents/skills/optimize-harness/SKILL.md`,
  `references/harness-map.md`, and `docs/tooling-dimensions.md` is updated to
  name `policy.toml` and drop the data tables from `harness_policy.py`.
- Clause 5 of the extraction decision gains `~/.config/ness/policy.toml`; that
  record receives the reciprocal link under its Issue heading, and a Position
  noting a separate policy repository as a possible later evolution.
- Plan threshold fires (more than one session): `PLAN.md` follows acceptance.

## Positions

- **YAML.** Rejected: nearly every entry is a regex or a glob containing `*`,
  `:` and backslashes, each of which needs quoting in YAML; TOML literal
  strings need none. The content is flat lists, where TOML reads better.
- **Filesystem overlay (overlayfs, mergerfs, bindfs, macFUSE).** Rejected:
  macOS has no native overlay and needs a system extension; Linux needs root or
  user namespaces; both are infrastructure for one file, and a mount an agent
  can unmount or shadow is not a boundary.
- **Submodule or symlink to a second checkout as the read source.** Rejected:
  `git checkout <branch>` inside that checkout changes the active policy and
  the guard sees no file write.
- **Environment variable or flag for the policy path.** Rejected: it is the
  override seam clause 2 forbids.
- **Proposals under `~/.config/ness/proposals/`.** Rejected: the control-plane
  fragment would need an exception, and the candidate would be tracked.
- **Cases as control plane.** Rejected: a case cannot weaken the guard, and
  making agents unable to add cases defeats the goal of agents doing the work.
- **Separate policy repository, independent of the engine.** Deferred: recorded
  in the extraction decision as a possible evolution and test harness for the
  extracted crate.

## References

- [2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md)
  — engine extraction this decision extends
- [2026-09-25-extend-destructive-command-policy](./2026-09-25-extend-destructive-command-policy.md)
  — the last policy change made by hand-editing `policy.rs`
