# Extract ness to its own repository

## Issue

`crates/ness` is the compiled PreToolUse guard every harness hook execs: 1,587
lines of Rust (1,125 source, 462 test harness), 124 guard corpus cases under
`tests/corpus/`, and 19 shim conformance cases under `tests/hook_corpus/`. Its
`policy.rs` is the sole implementation of the shared safety policy (protected
paths, secret-content patterns, dangerous commands, and the control-plane
file list that keeps agents from editing the guard's own inputs). Every shim
execs `$HOME/.local/bin/ness` by absolute path and fails closed when it is
missing: `.claude/hooks/scripts/{bash,write}-guard.sh`,
`.codex/hooks/scripts/{bash,write}-guard.sh`, `.grok/scripts/harness-guard.sh`,
`.config/crush/hooks/harness-guard.sh`, `.config/opencode/plugins/harness.ts`,
`.pi/agent/extensions/harness.ts`, and the hand-written
`.omp/agent/hooks/pre/harness-guard.ts`.

Three things couple the crate to this repository today:

| Coupling | Where |
|---|---|
| Shim conformance tests exec shim scripts at repo-relative paths with a fresh `$HOME` and `ness` symlinked into `.local/bin` | `crates/ness/tests/corpus.rs`, `shim_path()` and `run_shim()` |
| The guard protects its own source as control plane | `CONTROL_PLANE_FRAGMENTS` includes `/crates/ness/(?!target)` |
| Repository tooling knows the crate's paths | `.gitleaks.toml` allowlists `^crates/ness/tests/corpus/`; `.typos.toml` cites `policy.rs`; `.graphifyignore` un-ignores `/crates/` |

The costs are the same as for `wt` (a Rust toolchain in `just check` and CI,
and `just ness-install` as the only install path) plus one that is specific to
a safety guard: the shims deny everything when the binary is absent, so a new
machine cannot use any harness until it has compiled Rust. The crate changed 17
times in the 90 days to 2026-10-12, about three times a week, which is why the
release path has to be fast and why this decision follows
[2026-10-12-extract-wt-to-its-own-repository](./2026-10-12-extract-wt-to-its-own-repository.md)
rather than running alongside it.

This decision implements clause 6 of
[2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](./2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md)
and amends it in one respect: `safety-policy.json` is deleted rather than
regenerated from `ness`, because nothing reads it (see clause 7 below).

## Status

This is a proposal that is **proposed**.

## Assumptions and Constraints

- Ordering. This decision is implemented only after clause 2 of the parity
  decision has landed, so the shim set is final: the `antigravity` and
  `cursor` shims are gone and their 4 hook-corpus cases with them, leaving 15
  cases across `grok` (5), `codex-write` (4), `crush` (4), and `claude-bash`
  (2). It also waits for `wt` to have shipped at least one release through the
  same pipeline.
- Hook latency. Claude Code hook runs measure about 95 to 113 ms at p50 in the
  last 30 days (`just harness-sessions`). Resolving a binary through a mise
  shim measures about 100 ms more, so the shims must keep executing a real
  binary by absolute path, not a mise shim.
- mise tool options include `postinstall`, and the `github:` backend picks
  assets by OS and architecture from their names
  ([mise.jdx.dev/dev-tools/backends/github](https://mise.jdx.dev/dev-tools/backends/github.html)).
- `renovate.json` automerges minor and patch updates only for non-`0.x`
  versions and waits 7 days before proposing any update.
- `.agents/harness/hooks/safety-policy.json` is rendered by
  `render_safety_policy()` in `scripts/agent-harnesses.py`. A search of the
  tree finds no reader of the file: the only references are the generator and
  its manifest entry in `generated-paths.json`. The string `safety-policy` in
  `.agents/harness/self-improve-policy.json` is unrelated: it is an autonomy
  category in the `never` list (also relied on by `docs/specs/README.md` and
  `docs/specs/001-self-improvement-loop.md`) and is not a file reference.
  `contract.json` is referenced by the shared instructions and stays.
- `ness` has no `--version` flag. mise does not need one; the pin is the
  version.

## Argument

Move `crates/ness` to `phatblat/ness` on the path `wt` proved, keep the shims
executing `~/.local/bin/ness`, a copy of the mise-installed binary, so
hook latency is unchanged, split the tests so each repository tests what it
owns, and keep `0.x` versioning so every policy bump lands here through a
reviewed pull request. **Chosen.** The guard is the one component where a
human should see each version change arrive, and `0.x` gets that from the
existing Renovate rules for free.

Keep `ness` here permanently and extract only `wt`. **Rejected**: the fail-closed
shims make the Rust toolchain a prerequisite for using any harness on a new
machine, which is the worst place for that dependency to sit.

Extract `ness` now, together with `wt`. **Rejected**: the shim set is about to
change under the parity decision, and the hook-corpus tests would have to be
split twice.

Have the shims call `mise x -- ness` or the mise shim so no installed copy needs
maintaining. **Rejected**: it roughly doubles per-tool-call hook latency on
every harness, measured above.

## Architectural Decision

1. **Repository.** `crates/ness` becomes `phatblat/ness`, seeded from
   `git subtree split --prefix=crates/ness`. `tests/corpus/` (124 guard cases)
   and `corpus.rs`'s guard tests move with it. `.gitleaks.toml`'s corpus
   allowlist and the `.typos.toml` note move with the code they describe.
2. **Versioning and release.** Versions stay `0.x` on purpose: under
   `renovate.json` a `0.x` dependency is never automerged, so each policy
   change reaches this repository as a pull request a human merges. Release
   mechanics match `wt`: `v*` tags, a release workflow building
   `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`, assets
   `ness-<version>-<target>.tar.gz` plus `SHA256SUMS`.
3. **Install and exec path.** `.config/mise/config.toml` pins
   `"github:phatblat/ness"` with a `postinstall` that copies the installed
   binary to `~/.local/bin/ness` with `install -m 755`, as `ness-install`
   does today. It is a copy, not a symlink: a symlink into the
   version-specific mise install directory dangles after a bump plus
   `mise prune`, and a dangling link makes every shim fail closed, denying
   every tool call on every harness. Every `mise install` of a new pin
   refreshes the copy; between a pin bump and that install the shims keep
   running the previous, intact binary. Every shim keeps executing
   `$HOME/.local/bin/ness` by absolute path and keeps failing closed when it
   is missing; their remedy text changes from `just ness-install` to
   `mise install ness`. `ness-build` and `ness-install` are removed;
   `ness-check-installed` is replaced by the shim tests in clause 4.
4. **Tests split by ownership.** The `ness` repository tests verdicts: the
   guard corpus, and hook-mode cases that feed each harness's native JSON on
   stdin and assert the native verdict, with no shim scripts. This repository
   tests its shims: the 15 remaining `hook_corpus` cases move to `tests/` and
   run each shim script against `~/.local/bin/ness` under a fresh `$HOME`, the
   same contract `run_shim()` enforces today. That suite replaces
   `installed_copy_matches_corpus` as the proof that the installed binary and
   the shims agree. The `ness` CI job in `agent-harness-parity.yml` becomes a
   shim-test job that installs `ness` through mise and needs no Rust.
5. **Control plane.** The checkout fragment is a precondition of the
   extraction, not a follow-up: before `crates/ness` is removed, this
   repository adds `CONTROL_PLANE_FRAGMENTS` entries (each with its `9xx`
   corpus case, as `policy.rs` requires) for the `ness` checkout's path on this
   machine and for `.config/mise/config.toml`, and only then drops
   `/crates/ness/`. The checkout covers the policy source. The mise config
   joins the control plane because after extraction its pin and `postinstall`
   decide which binary runs as the guard, so an agent that can edit it can
   swap the guard. The cost is that no agent edits any mise pin directly;
   Renovate and the human-run `upgrade-*` recipes are unaffected. The checkout
   location is fixed in the plan, under `~/dev/` per this repository's layout,
   and the fragment names it exactly. There is no window in which the policy
   source or its install pin is unprotected.
6. **Toolchain leaves `check`.** With both crates gone, `install-rust-deps` is
   no longer a dependency of anything in `just check`, and `rust.just` keeps
   only toolchain maintenance (`install-rust-deps`, `update-rust`,
   `clean-rust`). `.graphifyignore`'s `!/crates/` line goes with the directory.
7. **`safety-policy.json` is deleted.** `render_safety_policy()`, the rendered
   file, and its `generated-paths.json` entry are removed. The `safety-policy`
   autonomy category in `self-improve-policy.json` stays: it is a different
   thing that shares the name, and removing it would let the self-improvement
   loop treat safety-policy changes as something other than human-only. This
   amends clause 6 of the parity decision, which had `ness` emit the file:
   with no reader, there is nothing to emit. `contract.json` is unaffected.
8. **Renovate and urgent bumps.** The `github:phatblat/` package rule from the
   `wt` decision applies (no 7-day wait, any-time schedule; `0.x` still never
   automerges, so each bump arrives as a pull request). An `upgrade-ness`
   recipe mirrors `upgrade-omp`: `mise upgrade --bump ness`, `hk fix` on the
   mise config, and a commit, for a policy fix that cannot wait for the next
   Renovate run.

## Positions

- **Promote to `1.0.0` like `wt` so bumps automerge.** Rejected: this is the
  safety policy; a version arriving unreviewed is the one outcome the guard
  exists to prevent.
- **Keep the hook-corpus tests in the `ness` repository and have it clone
  dotfiles in CI.** Rejected: it couples the guard's CI to this repository's
  layout and tests files it does not own.
- **Have `ness` emit `safety-policy.json` as the parity decision said.**
  Rejected: nothing reads the file, so emitting it from either place is work
  with no consumer.
- **Resolve the binary through `PATH` like `wt`.** Rejected: harness hook
  processes do not run `mise activate`, and the absolute path is what makes
  the fail-closed check unambiguous.
