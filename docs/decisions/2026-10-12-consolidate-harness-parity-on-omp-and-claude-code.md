# Consolidate harness parity on OMP and Claude Code

## Issue

This repository keeps nine agent harnesses in parity: a 405-cell capability
registry (`scripts/harness_capabilities.py`), 458 generated files
(`.agents/harness/generated-paths.json`), a daily probe LaunchAgent
(`at.phatbl.harness-probe`) that appends `docs/harness/drift.jsonl` and
re-renders `docs/harness/*.md`, and two Rust crates (`crates/ness`,
`crates/wt`) whose binaries every harness hook shim executes. Three shells
(Nushell, Zsh, Bash) are mirrored the same way. The stated purpose was to keep
every harness "ready to go" as a fallback and to accumulate evidence for
extracting the parity system as a product (`docs/tooling-dimensions.md`,
"Extraction decision").

Measured against actual use, the parity is paid for and not used. Session
transcripts for the last 30 days (`just harness-sessions`):

| Harness | Sessions (30d) | Older sessions on disk | Last seen |
|---|---|---|---|
| omp | 400+ (scanner cap) | 1236 | 2026-10-12 |
| claude | 5 | 3 | 2026-10-12 |
| cursor | 7 | 1 | n/a |
| codex | 1 | 399 | 2026-10-10 |
| antigravity | 1 | 0 | 2026-09-18 |
| opencode | 0 | 1 | 2026-06-08 |
| pi, grok, crush | 0 | 0 | never |

The drift ledger produced the churn the parity system was meant to prevent. Of
238 records, 137 (58%) are CLI version bumps for tools that
`.config/mise/config.toml` already pins and Renovate already bumps. The other
56 state changes break down as 25 caused by this repository's own skill
additions and renames (caught equally by `harness-check` in CI), 25 hand edits
to registry cells, and 6 flaps of the opencode validation probe under launchd.
Zero records show a vendor changing behavior. All 36 "capture harness drift"
commits were made by hand. Coverage is 22% (91/405), below the 30% threshold
at which the same document says to abandon the product framing.

OMP, which accounts for essentially all use, already reads `~/.agents/skills`
natively (priority 70 after its own `~/.omp/agent/skills`), along with
`~/.claude/skills`, `~/.codex/skills`, and `~/AGENTS.md`
([omp.sh/docs/skills](https://omp.sh/docs/skills)). Only 7 of the 458
generated paths target `.omp`. The shared layer is already OMP-native; the
generator exists for the harnesses that are not used.

## Status

This is a proposal that is **proposed**.

## Assumptions and Constraints

- OMP is the primary harness and Claude Code the second, by measured use. Both
  stay fully configured.
- A fallback harness is one that can be started with the shared skills, the
  shared instructions, and the safety guard, and nothing else. This is the
  depth chosen in the brainstorm on 2026-10-12.
- Codex, OpenCode, Pi, Grok, and Crush read `~/.agents/skills` and `AGENTS.md`
  natively (`.agentlink/providers/*.toml`,
  `docs/tooling-dimensions.md`). Cursor and Antigravity do not at user scope,
  which is why 182 of the 458 generated files are adapter copies (skills,
  commands, agents) for those two.
- Claude Code documents that a `~/.claude/skills/<name>` entry may be a symlink
  to a directory elsewhere and that unknown frontmatter keys are ignored
  ([code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)).
  OMP documents `disable-model-invocation` as a skill frontmatter field with the
  same meaning ([omp.sh/docs/skills](https://omp.sh/docs/skills)). So the
  manual-only flag can live in the shared `SKILL.md` and the Claude pointer
  files can become symlinks.
- OMP's `skill://<name>` URL resolves to that skill's `SKILL.md` and
  `skill://<name>/<path>` to a file inside it. It is a path alias; the docs
  make no token or performance claim beyond the lazy loading every harness
  already does. A `~/.agents/skills/<name>/...` path costs the same in OMP and
  works everywhere else.
- `ness` changes about three times a week (17 commits in 90 days) and its 19
  hook-corpus tests execute the shim scripts under `.claude/hooks` and
  `.codex/hooks`. `wt` changed 5 times in 90 days and has no coupling to this
  repository beyond the shell wrappers that exec `~/.local/bin/wt`.
- `.config/mise/config.toml` already pins nine tools with the `github:` backend
  and Renovate already bumps that file, so a GitHub-release binary pinned there
  is the established update path.
- The identity of the scripts and Nushell functions is unchanged: scripts are
  Bash, the LaunchAgents only need `PATH` from `zsh -l`, and interactive use is
  Nushell.

## Argument

Keep full configuration for the two harnesses in use and reduce every other
harness to what it reads for free plus the safety guard. Retire the daily probe
now on the evidence above rather than at day 90. Move `wt` out immediately and
`ness` once the shim set it tests has settled. Freeze Zsh. **Chosen.** This
removes the generated surface that produces the churn while keeping the two
things a fallback actually needs, and it does so without inventing a new sync
mechanism.

Keep all nine harnesses and automate the parity harder: an OMP `tool_result`
hook regenerates on every change, and the probe is folded into `pr-daily`.
**Rejected**: the objection is keeping nine harnesses, not how they are
regenerated. The 458 files and the registry remain, the churn moves into one
daily commit instead of disappearing, and the OMP hook only fires for edits
made inside OMP. Regeneration in the hk pre-commit hook is not the rejected
part; clause 4 adopts it for the harnesses that stay.

Fork the shared skills to OMP-native `skill://` references and generate
portable copies for other harnesses. **Rejected**: `skill://` is an alias with
no measured gain, the shared skills contain one textual cross-reference today,
and the fork would add a generation step to audit for no benefit.

Fix only the drift churn and extract the crates, deferring the harness and
shell questions. **Rejected**: it leaves seven adapter trees regenerating on
every skill edit, which is the cost this decision exists to remove.

## Architectural Decision

1. **Tiers.** OMP and Claude Code are primary: commands, agents, hooks,
   permissions, and MCP stay configured for both. Codex, OpenCode, Pi, Grok,
   and Crush are fallbacks: they get the shared skills they already read from
   `~/.agents/skills`, the shared `AGENTS.md`, and their existing `ness` guard
   shim. Nothing else is generated for them. Cursor and Antigravity leave the
   user-tier generator entirely; their project-tier skill links through
   agentlink are unchanged.
2. **Generator scope.** `scripts/agent-harnesses.py generate` emits only: the
   Claude skill entries under `~/.claude/skills` as symlinks into
   `~/.agents/skills`; the shared hooks contract and the shim files each
   fallback's guard needs; the shared instructions; and the rendered
   registry docs. Everything else it emits today is deleted from the tree and
   from `generated-paths.json`: the `antigravity` and `cursor` adapters (182
   files), the
   `.codex/skills` pointers (Codex reads the `agents/openai.yaml` sidecars in
   the shared skill directories natively), and the fallback agents, commands,
   permissions, and MCP adapters. `disable-model-invocation: true` moves from
   rendered pointer frontmatter into the shared `SKILL.md` of each manual-only
   skill. `validate` keeps pinning the command and agent counts for the two
   primaries.
3. **Probe and ledger.** The `at.phatbl.harness-probe` LaunchAgent is
   uninstalled and its plist removed. The `probe` and `drift` subcommands,
   `docs/harness/drift.jsonl`, `docs/harness/versions.json`, and
   `docs/harness/drift.md` are deleted. The capability registry stays as
   static documentation rendered by `generate`, and the weekly
   `agent-harness-parity.yml` audit keeps refreshing the parity issue. The
   "Extraction decision" section of `docs/tooling-dimensions.md` is rewritten
   to record that the abandon criterion was invoked early, on 2026-10-12, with
   the evidence in this decision's Issue.
4. **Generation trigger.** Regeneration happens in the hk `pre-commit` hook: a
   `generate` step declared after `guard-test-identity` with `exclusive = true`
   runs `just generate` before every lint step and stages the output roots it
   declares. This landed with this decision. No OMP hook, Tern hook, or
   LaunchAgent regenerates files.
5. **wt.** `crates/wt` moves to its own repository first, installed back
   through mise's `github:` backend and bumped by Renovate. The terms are in
   [2026-10-12-extract-wt-to-its-own-repository](./2026-10-12-extract-wt-to-its-own-repository.md).
6. **ness.** `crates/ness` follows once clause 2 has landed and `wt` has shipped
   a release, with the shim-corpus tests split by ownership and the shims still
   executing `~/.local/bin/ness` by absolute path. The terms are in
   [2026-10-12-extract-ness-to-its-own-repository](./2026-10-12-extract-ness-to-its-own-repository.md),
   which also deletes `safety-policy.json` rather than having `ness` emit it,
   since nothing reads the file.
7. **Shells.** Zsh is frozen: no new functions, no requirement that a Nushell
   function has a Zsh twin, and the coverage table in `docs/functions.md` is
   replaced by a one-line statement of the freeze. Existing Zsh functions,
   their lint steps, and their bats tests stay. Deleting them is a separate
   decision.
8. **Skill cross-references.** Skills reference other skills and their files
   by `~/.agents/skills/<name>/...` path, never by `skill://`. A skill that
   wants OMP-specific behavior says so in one conditional sentence in prose;
   no per-harness skill variants are generated.

Clauses 1 through 3 and 5 span more than one session; the Plan threshold fires
and a `PLAN.md` follows acceptance.

## Positions

- **Keep Cursor's user-tier skill copies (7 sessions in 30 days).** Rejected:
  Cursor's copies are 113 of the 182 adapter files, Cursor's project-tier link
  through agentlink already works, and the sessions are too few to justify the
  only non-native delivery path left.
- **Keep Codex as the sole fallback for OpenAI-subscription model access.**
  Rejected as the only fallback, accepted as one of five: at skills-plus-shim
  depth the other four cost nothing beyond a shim that already exists.
- **Retire the ledger at day 90 (2026-11-27) per the written criterion.**
  Rejected: six more weeks of daily hand commits cannot change a result the
  evidence already settles.
- **Fold the probe into `pr-daily`.** Rejected: it relocates the churn into
  the daily PR without reducing it.
- **Run the probe in a cloud container.** Rejected: CI runs with no harness
  CLIs installed, so every version probe reads "unavailable"; installing nine
  CLIs to read nine `--version` strings duplicates what Renovate records.
- **Extract `ness` now.** Rejected: at three changes a week a two-step
  release-then-bump cycle slows the safety policy, and the shim set it tests
  is about to change under clause 2.
