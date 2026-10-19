# Move the ness safety policy out of code into a TOML file

## Issue

Every rule the guard enforces is a table in code: the regex statics in
`crates/ness/src/policy.rs` (`CONTROL_PLANE_FRAGMENTS`, `PROTECTED_PATHS`,
`SECRET_CONTENT`, `DANGEROUS_COMMANDS`, `INTERACTIVE_LAUNCH`, the write-target
extractors, and the rest) and the approval baselines in
`scripts/harness_policy.py` (`BASH_ALLOW_PREFIX`, `BASH_ASK_PREFIX`,
`BASH_DENY_PREFIX`, the per-harness modes). Both files are control plane, so
the guard denies agent edits to them. That is the right boundary: no sequence
of agent tool calls may change what the guard permits.

The cost lands on the human. A one-line policy change means hand-editing a
Rust regex table, a JSON corpus case, and sometimes a Python tuple, rebuilding,
`just ness-install`, and committing. The agent can only describe the change in
chat. The `gh auth token` deny added this week took edits in `policy.rs` and
three corpus files; the `rm`-under-`/tmp` approval carve-out was hand-written
into `~/.omp/agent/config.yml` instead, where the next
`just harness-perms-apply` overwrites it, and opencode never got it. The review
surface is three languages for a decision that is a list entry.

This decision keeps the boundary and changes the review surface: the policy
becomes data the agent can draft and test, and the human's part becomes one
decision per change.

This decision extends
[2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md):
the engine extraction proceeds as written there except where this record
amends it (clauses 4 and 12 below).

## Status

This is a proposal that is **accepted**.

## Assumptions and Constraints

- The security property is unchanged and is the same strength as today: the
  guard matches text in tool inputs. An agent must not be able to change the
  active policy through any input the guard sees. This decision does not claim
  to close channels the guard cannot see today (an `eval` tool spawning a
  shell, a PTY-backed bash tool typing into an interactive prompt); it must
  not open new ones.
- The guard fails closed on a missing, malformed, unverified, or erroring
  policy, the opposite of `generated-paths.json` (`manifest.rs:14-17`),
  because a guard with no rules is a guard that allows everything.
- The crate uses `fancy-regex` (`Cargo.toml`), and the current tables depend on
  lookaround (`(?=…)` in `DANGEROUS_COMMANDS`, `(?!…)` in
  `CONTROL_PLANE_FRAGMENTS`). The policy file's patterns are `fancy-regex`
  expressions and are transcribed verbatim, never rewritten.
- `fancy-regex` can fail at match time, not only at compile time. Today
  `matches()` (`policy.rs:65-66`) maps a runtime error to "no match", which is
  fail-open; the data-driven engine maps it to deny.
- Hook latency budget: Claude Code hook runs measure 95 to 113 ms p50
  (`just harness-sessions`). Parsing one TOML file, hashing it, and compiling
  about forty patterns adds single-digit milliseconds; the implementation
  measures this and the Decision is revised if it exceeds 10 ms p50.
- Current corpus: 127 guard cases in `crates/ness/tests/corpus/*.json`, all
  passing against the compiled tables, so their expectations are the
  equivalence oracle for the transcription. The shim-conformance cases in
  `crates/ness/tests/hook_corpus/` are owned by the extraction decision and are
  not moved by this one.
- `.config/ness/policy.toml` is tracked in this repository, which is `$HOME`.
  `git checkout`, `git pull`, `git stash`, and `git rebase` are allowed
  commands that can rewrite a tracked file without the guard seeing a write.
  Tracking alone therefore cannot be what makes the file trustworthy; clause 3
  is.
- `tomllib` is in Python's standard library (3.11+); `toml` + `serde` are
  available to the crate.
- The GitHub-PR-merge gate (0.x + Renovate in the extraction decision) depends
  on the agent's `gh` token not being able to edit branch protection. ness does
  not deny `gh api` writes today. A local gate does not have that dependency.

## Argument

Put every policy table in one TOML file that both ness and
`harness_policy.py` read, with `ness policy check` and `ness policy apply` as
the proposal workflow and a load-time hash check tying the active policy to the
last human `apply`. **Chosen.** One review surface, one human action per
change, and the control-plane boundary is the same mechanism as today.

Keep regexes in Rust and move only the lists. **Rejected**: two homes for policy
for an indefinite period, and the regex tables are exactly the ones a human
cannot review in Rust source.

Ship the policy as a release asset of the ness repository with PR merge as the
gate. **Deferred** to a Backlog item: the right shape for policy shared beyond
one user is an adoptable standard, and that is a different problem from this
one.

Include the `rm`-under-a-root approval carve-out in this decision.
**Deferred** to a Backlog item: it needs per-harness glob semantics that are
not yet verified, and it lands independently of the data move.

Bring the policy in from another checkout through a filesystem overlay or a
submodule. **Rejected**: see Positions.

## Architectural Decision

1. **One policy file.** `~/.config/ness/policy.toml`, tracked at
   `.config/ness/policy.toml`. Every table that exists in `policy.rs` or
   `harness_policy.py` today moves; the engine keeps no pattern of its own
   except clause 3's floor. Tables:

   ```toml
   [control_plane]                 # CONTROL_PLANE_FRAGMENTS
   [protected_paths]               # PROTECTED_PATHS
   [secret_content]                # SECRET_CONTENT
   [commands.privilege_escalation] # PRIVILEGE_ESCALATION
   [commands.dangerous]            # DANGEROUS_COMMANDS
   [commands.obfuscated]           # OBFUSCATED_EXECUTION
   [commands.credential_disclosure]
   [commands.interactive_launch]
   [commands.warn]                 # COMMIT_COMMAND (main-branch warning)
   [write_targets]                 # redirect, mutating_argv, sed_inplace, dd, path_token
   [approval]                      # bash allow_prefix, allow_exact, prompt_prefix, deny_prefix
   [approval.modes]                # claude_default_mode, omp_approval_mode,
                                   # opencode_edit, opencode_external_directory, opencode_webfetch
   [approval.claude]               # webfetch_domains, tools
   ```

   Every pattern is a TOML literal string (`'...'`) holding a `fancy-regex`
   expression, inline flags included (`(?i)`), compiled at load. The named
   capture group `span` that `write_targets` entries must define is part of the
   schema; `check` rejects an entry that drops it.
2. **Loading and fail-closed.** ness loads the file on every invocation from
   that fixed path. There is no flag or environment variable to point it
   elsewhere: an override seam is an agent-reachable way to swap the policy. A
   missing, unparseable, uncompilable, or unverified (clause 3) policy makes
   every `guard` and `hook` verdict `deny` with a reason naming the path and
   `ness policy check`. A runtime match error is a `deny`, not a non-match.
3. **Verified against the last human apply.** `~/.local/state/ness/applied.json`
   records the sha256 of the policy as applied and of the case set at that
   time. On every load ness recomputes the policy hash and denies everything on
   mismatch. A `git checkout` or `git pull` that changes `policy.toml` thereby
   disables the guard until a human runs `apply` on that machine. The engine
   keeps one hardcoded table, `REQUIRED_PROTECTION`: `policy.toml`,
   `applied.json`, `~/.local/bin/ness`, and the command `ness policy apply`.
   `check` rejects, and `apply` refuses, a candidate whose `[control_plane]`
   and `[commands.dangerous]` do not cover them.
4. **Corpus as data.** The 127 guard cases move verbatim to
   `~/.config/ness/cases/*.json`, tracked, in their current JSON shape. The
   directory is **not** control plane: an agent writing or deleting a case
   cannot weaken the guard, and clauses 5 and 6 make a deletion visible and
   require the human to accept it. The crate keeps a fixture policy and a
   handful of fixture cases for engine unit tests. This amends clause 1 of the
   extraction decision, which moved these cases into the ness repository; the
   shim-conformance cases follow that decision's clause 4 unchanged.
5. **`ness policy check <candidate>`.** Exit 0 or 1. Reports, in order: schema
   and regex compile errors; clause 3 invariants; every case in `cases/` run
   against the candidate, with failures; the **verdict diff**, each case whose
   decision or reason differs between the active policy and the candidate;
   and the case-set delta (added, removed, changed) against the hash in
   `applied.json`. Removed or changed cases are exit 1. When the active policy
   cannot be loaded, the verdict diff section says so and is skipped; the rest
   of `check` runs, so recovery from a broken active policy is possible.
6. **`ness policy apply <candidate>`.** Runs `check`; refuses on exit 1 unless
   the only failures are removed or changed cases and the human passes
   `--accept-case-changes`, which prints the delta and requires an interactive
   `yes`. Refuses without a TTY on stdin. Replaces the active file by atomic
   rename and writes `applied.json`. `[commands.dangerous]` lists
   `ness policy apply` and clause 3 keeps it there, so the guard denies the
   command string when an agent issues it; a human runs it from a terminal.
7. **`ness policy active`.** The default for a bare `ness policy`: prints the
   active path, sha256, verification state against `applied.json`, applied
   timestamp, and the entry count per table. Works when the policy is broken,
   and says why.
8. **Proposals.** An agent writes a full candidate file to
   `~/.local/state/ness/proposals/<slug>/policy.toml` (untracked, not control
   plane), adds cases to `cases/`, runs `check`, and reports the verdict diff.
   Under `~/.config/ness/`, only `policy.toml` is denied to agents.
9. **`harness_policy.py` becomes a transform.** The `BASH_*`, mode, webfetch,
   and Claude tool tuples are deleted; `bash_rules(style)` reads `[approval]`
   with `tomllib` and renders it per harness (`claude`, `claude-deny`,
   `antigravity`, `opencode`, `omp`) exactly as today. `harness-apply.py
   perms` and `scripts/agent-harnesses.py` keep their interfaces. The file
   stays control plane: it is the renderer the generated permission files
   trust. With no table changes, every rendered permission surface is
   byte-identical before and after.
10. **Shims unchanged.** Every hook still execs `~/.local/bin/ness` by absolute
    path. The fail-closed remedy text names the policy path and the state.
11. **Acceptance.** The initial `policy.toml` is a verbatim transcription of
    the compiled tables. Accepted when: `ness policy check` passes all 127
    migrated cases (their expectations are the pre-change verdicts, so a full
    pass is an empty verdict diff); the shim-conformance cases pass; the
    permission files rendered by `agent-harnesses.py generate` and the
    `bash.patterns` written by `harness-apply.py perms` are byte-identical to
    before; a `git checkout` of a modified `policy.toml` produces deny on the
    next hook; and the latency measurement in Assumptions holds.
12. **Extraction decision amendments.** Clause 1 there no longer moves
    `tests/corpus/` to the ness repository (clause 4 here). Clause 5 there
    gains `~/.config/ness/policy.toml` and `~/.local/state/ness/applied.json`
    as control-plane entries. The reciprocal note under its Issue heading
    records both.

## Consequences

- A policy change becomes: agent drafts candidate and cases, runs `check`,
  reports the verdict diff; human reads it and runs `ness policy apply`, then
  commits `.config/ness/`. The Rust engine changes only when a new *kind* of
  rule appears.
- Every machine requires one human `apply` after pulling a policy change,
  because `applied.json` is local state. Until then every hook denies, with a
  reason that says so.
- The `rm`-under-`/tmp` rules hand-written into `~/.omp/agent/config.yml` on
  2026-10-17 stay as they are until the deferred `rm` roots item lands; they
  remain subject to being overwritten by `just harness-perms-apply`.
- The control-plane list in `.agents/skills/optimize-harness/SKILL.md`,
  `references/harness-map.md`, and `docs/tooling-dimensions.md` is updated to
  name `policy.toml` and `applied.json` and to drop the data tables from
  `harness_policy.py`.
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
  the guard sees no file write. Clause 3 exists because the same is true of a
  tracked file in this repository.
- **Trust the tracked file without a hash check.** Rejected: allowed git
  commands rewrite tracked files without a guarded write; the hash check is
  what makes `apply` the only path.
- **Environment variable or flag for the policy path.** Rejected: it is the
  override seam clause 2 forbids.
- **Proposals under `~/.config/ness/proposals/`.** Rejected: the control-plane
  fragment would need an exception, and the candidate would be tracked.
- **Cases as control plane.** Rejected: a case cannot weaken the guard, and
  making agents unable to add cases defeats the goal of agents doing the work.
  Deletion is handled by the delta check and the human acceptance in clause 6.
- **`rm` roots in this decision.** Deferred: see Argument.
- **Separate policy repository, independent of the engine.** Deferred: recorded
  in the extraction decision as a possible evolution and test harness for the
  extracted crate.

## References

- [2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md)
  — engine extraction this decision extends and amends
- [2026-09-25-extend-destructive-command-policy](./2026-09-25-extend-destructive-command-policy.md)
  — the last policy change made by hand-editing `policy.rs`

## Errata

- 2026-10-18: Clauses 3 and 5 say `applied.json` records one sha256 of the
  case set. It shipped as `Applied.cases: BTreeMap<name, sha256>`, one hash
  per case file, so `check` can name each added, removed, or changed case.
  The decision is unchanged.
- 2026-10-18: Clause 3 names a single `REQUIRED_PROTECTION` table. The floor
  shipped as `active::REQUIRED_PROTECTED_PATHS` (matched against
  `[control_plane]` after lexical normalization) plus
  `active::REQUIRED_DENIED_COMMAND` (matched against `[commands.dangerous]`),
  checked by `check_required_protection`. The decision is unchanged.
- 2026-10-18: Clause 1 says the engine owns no pattern of its own. It adds an
  engine-side `(?i)` to `[control_plane]` when compiling, as the old
  `CONTROL_PLANE_PATHS` static had, so a policy edit cannot make the table
  that guards the guard's own inputs case-sensitive. The decision is
  unchanged.
- 2026-10-18: Clause 8 says only `policy.toml` is denied to agents under
  `~/.config/ness/`. Four case files are also denied because their names
  match `[protected_paths]` by name alone: `050-…-id_ed25519.json`,
  `051-…-.env.json`, `058-…-.git-credentials.json`, `074-…-kubeconfig.json`.
  This fails closed and is an extra pin on those patterns, so the files keep
  their names; an agent that needs to change one asks a human. The decision
  is unchanged.
- 2026-10-18: Positions omitted one alternative. A test-only gate for `apply`
  (an `--for-tests` flag that skipped the TTY check when `$HOME` was under the
  temp dir) was rejected: any such gate is bypassable by an agent that owns
  the test home. The corpus runner writes `applied.json` directly instead.
- 2026-10-18: Clause 9 does not say which verification `harness_policy.py`
  applies. `load_approval()` reads the checkout's `policy.toml` with no
  `applied.json` hash check: the rendered permission files trust the tracked
  file, the same exposure the hardcoded tuples had. The guard's rule (clause
  3) is stricter and separate. The decision is unchanged.
- 2026-10-19: The latency measurement in Assumptions and clause 11 was taken:
  `ness guard --harness claude --tool bash --command 'git status'`, 200 runs
  per binary, four rounds, pre-change binary against the data-driven one
  with an applied policy. The data-driven engine adds 2.6–3.0 ms p50
  (9.1–15.6 ms → 12.2–18.5 ms; absolute figures drift with machine load,
  the delta does not), within the 10 ms budget. The decision is unchanged.
