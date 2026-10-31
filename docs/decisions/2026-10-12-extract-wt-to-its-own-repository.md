# Extract wt to its own repository

## Issue

`crates/wt` is a 1,613-line Rust binary (957 source, 656 tests) that resolves
git worktrees under the `~/.worktrees/<path-key>/<branch>` convention and
links overlay files into them. It has no dependencies beyond the standard
library and no coupling to this repository's code: the only callers are two
shell wrappers (`.config/zsh/functions/wt`, `.config/nushell/autoload/wt.nu`)
that exec `wt` from `PATH` and act on the directory it writes to `--cd-file`,
and `tests/wt-wrapper.bats`, which tests those wrappers against a stub and
never builds the crate. Its user configuration, the overlay manifests under
`.config/wt/overlay/`, is read at runtime from `~/.config/wt/overlay/<path-key>`
or `$WT_OVERLAY_DIR` and stays dotfiles content either way.

Living in dotfiles costs this repository a Rust toolchain. `just check` depends
on `wt-test`, which depends on `install-rust-deps` (rustup, stable, llvm-tools);
the `wt` job in `.github/workflows/agent-harness-parity.yml` installs mise,
rust, sccache, and zsh on every relevant pull request to run `cargo test`; and
`just wt-install` is the only way a machine gets the binary, so a second
machine needs the toolchain before it can `cd` into a worktree. The crate
changed 5 times in the 90 days to 2026-10-12, so it is stable enough that a
release cadence costs little.

This repository already consumes nine tools as prebuilt GitHub release
binaries through mise's `github:` backend (`.config/mise/config.toml`), and
Renovate's `mise` manager bumps those pins (for example
`chore: bump github:raine/aven 0.1.45 → v0.1.46`, 2026-10-07). That is the
established path for a binary this repository depends on but does not need to
compile.

This decision implements clause 5 of
[2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](./2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md)
and goes first because `wt` proves the release and pin path that
[2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md)
then reuses for the safety guard.

## Status

This is a proposal that is **accepted**.

## Assumptions and Constraints

- mise's `github:` backend downloads one release asset per install and picks it
  by OS, CPU architecture, and C library from the asset names; tags are read as
  `v<version>` by default
  ([mise.jdx.dev/dev-tools/backends/github](https://mise.jdx.dev/dev-tools/backends/github.html)).
  Assets named with the Rust target triple satisfy that autodetection without
  `asset_pattern`.
- Renovate's `mise` manager lists the `github` backend among those it supports
  and this repository's history shows it bumping such pins.
- `renovate.json` sets `minimumReleaseAge` to 7 days for every dependency and
  automerges minor and patch updates only when the current version is not
  `0.x`.
- Interactive shells here run `mise activate`, which puts the real install
  directories on `PATH` rather than shims, so a `wt` call from a wrapper pays
  no mise overhead. Nothing execs `wt` by absolute path.
- `wt shell` falls back to `zsh -i`, so the crate's own test suite needs zsh
  on Linux runners, as the current CI job already documents.
- GitHub Actions in the new repository follow `.claude/rules/github-actions.md`:
  external actions pinned to a full SHA with a tag comment, Node 24-capable
  versions only.

## Argument

Move `crates/wt` to `phatblat/wt` with its history, publish release binaries
for `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`, pin it in mise, and
let Renovate bump it. Delete the crate, its three recipes, and its CI job from
this repository, keeping the wrappers, the overlay manifests, and the wrapper
tests. **Chosen.** The boundary already exists at the binary; this decision
makes the install path match it and removes a toolchain from `just check`.

Keep `crates/wt` here and only cache the Rust build in CI. **Rejected**: every
new machine still needs rustup before `wt` works, and `just check` still
compiles Rust for a tool that changes five times a quarter.

Publish `wt` to crates.io and install with mise's `cargo:` backend. **Rejected**:
`cargo:` compiles on install, so the consumer still needs a toolchain, and a
public crate name is a commitment this tool does not need.

Vendor the binary into `bin/`. **Rejected**: a 400 KB Mach-O in git history on
every release, no Linux build for CI, and no provenance.

## Architectural Decision

1. **Repository.** `crates/wt` becomes `phatblat/wt`, seeded from
   `git subtree split --prefix=crates/wt` so the crate's history is preserved.
   `Cargo.toml` gains `license = "MIT"`, this repository's copyright
   convention, and keeps `publish = false`; crates.io publication is not part
   of this decision.
2. **Versioning and release.** The first release is `v1.0.0`: the tool's
   command-line contract (`wt [<branch>] | wt <action> [<branch>] [flags]`,
   `--cd-file`, `WT_OVERLAY_DIR`, exit codes) is already stable and relied on,
   and a `1.x` version lets this repository's existing Renovate rule automerge
   minor and patch bumps. Later releases follow semver. A release workflow in
   the new repository builds `aarch64-apple-darwin` and
   `x86_64-unknown-linux-gnu`, uploads `wt-<version>-<target>.tar.gz` for each
   plus a `SHA256SUMS` file, and runs on `v*` tags.
3. **Tests travel with the code.** `crates/wt/tests/{overlay,shell,worktree}.rs`
   move with the crate. The new repository's CI runs `cargo test` on macOS and
   Ubuntu with zsh installed. `tests/wt-wrapper.bats` stays here, unchanged: it
   tests the wrappers against a stub and needs no binary.
4. **Install.** `.config/mise/config.toml` pins `"github:phatblat/wt" = "1.0.0"`.
   The binary is reached through `PATH` from `mise activate`, as every other
   mise tool is. `~/.local/bin/wt` and the `wt-build`, `wt-install`, and
   `wt-test` recipes are removed; `check` no longer depends on `wt-test`.
5. **Removal.** `crates/wt` is deleted from this repository along with the `wt`
   job in `.github/workflows/agent-harness-parity.yml` and its zsh install
   step. The wrapper comments that point at `crates/wt` and `just wt-install`
   point at the new repository and `mise install` instead.
6. **Configuration stays here.** `.config/wt/overlay/default` and
   `.config/wt/overlay/dotfiles` are user configuration and remain dotfiles
   content. The manifest format and lookup order
   (`$WT_OVERLAY_DIR`, then `~/.config/wt/overlay/<path-key>`, then `default`)
   are documented in the new repository's README and do not change.
7. **Renovate.** A `packageRules` entry matching `github:phatblat/` dependencies
   sets `minimumReleaseAge` to `0 days`, `schedule` to `["at any time"]`, and
   `groupName` to `phatblat tools`. All three are needed: `renovate.json` sets
   a top-level `schedule` of `before 9am on monday`, so zero cooldown alone
   would still hold a mid-week release until Monday, and left in the weekly
   `mise tools` group the pin would share a branch with updates that keep that
   schedule and the 7-day cooldown. With all three, a release made here lands
   in the next Renovate run rather than a week later. Combined with the `1.x`
   automerge rule, a `wt` bump merges with no delay and no human review; that
   is acceptable for a self-owned tool and is stated here so it is a choice,
   not a surprise. The existing automerge rule otherwise applies. An
   `upgrade-wt` recipe is not added; `mise upgrade --bump wt` covers the rare
   out-of-band bump.

## Positions

- **Extract `wt` and `ness` in one move.** Rejected: `ness` changes three times
  a week and its tests exec shim scripts that live here; `wt` has neither
  problem, so it goes first and proves the path.
- **Keep the `wt` CI job here running against the released binary.** Rejected:
  nothing here tests the binary's behavior once the crate is gone; the wrapper
  tests already use a stub, and the binary's tests run in its own repository.
- **Start at `v0.1.0` to match `Cargo.toml` today.** Rejected: under
  `renovate.json` a `0.x` dependency is never automerged, so every `wt` bump
  would wait on a manual merge for a tool whose contract has not changed in
  weeks.
- **Build a universal macOS binary.** Rejected: every machine this repository
  runs on is Apple silicon or an Ubuntu runner; a second macOS target is added
  when a machine needs it.
