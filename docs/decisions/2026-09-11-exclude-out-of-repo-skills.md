# Exclude out-of-repo skills from harness generation

## Issue

`.agents/skills` holds five entries that are symlinks into checkouts outside
this repository: `authoring-skills`, `recording-changes`,
`semantic-versioning`, and `setup-phatblat-skills` point into
`~/dev/agents/skills` (`phatblat/skills`), and `conventional-docs` points into
`~/dev/agents/conventional-docs`. `scripts/agent-harnesses.py` discovered
skills with `SKILL_SOURCE.glob("*/SKILL.md")`, which matches only what exists,
so generation was environment-dependent: on the maintainer's machine the five
resolved and were rendered as `antigravity`/`cursor` adapter wrappers, while in
CI (`HOME=$GITHUB_WORKSPACE`, no sibling checkouts) the same symlinks dangle and
those wrappers were reported obsolete with `generated-paths.json` stale. Three
commits pruned the artifacts — `82c10b0`, `a46fc29`, `f140928` (PR #473) — and
each time the next local `just harness-generate` put them back. This decision
makes the generated set a function of the committed tree alone. It partially
supersedes clause 8 of
[2026-09-07-adopt-conventional-docs](./2026-09-07-adopt-conventional-docs.md),
which recorded that the symlinked skills' generated adapters are committed.

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- The five skills stay symlinked and stay tracked: every harness that scans
  `~/.agents/skills` keeps loading them on the maintainer's machine, and the
  symlink is what keeps them current without a vendored copy.
- No other environment can resolve them: CI checks out this repository alone,
  and so does every other clone.
- `Path.resolve()` is lexical for a missing target, so a symlink's target is
  readable whether or not it exists — the property this decision relies on.
- `scripts/agent-harnesses.py` is control plane
  (`crates/ness/src/policy.rs`'s `CONTROL_PLANE_FRAGMENTS`), so the rule itself
  lives in the agent-editable `scripts/harness_skills.py` and the control-plane
  file only calls it.

## Argument

Deciding from the symlink target rather than from the target's existence is what
makes `generate` reproducible across machines: the target string is committed,
so every checkout reaches the same verdict. **Chosen.**

Vendoring the two external repositories into this tree — `git-subrepo` is
already a CI dependency — would give CI the real files and render adapters for
all five skills everywhere. **Rejected**: it duplicates content that has its own
repository and adds a resync step to every upstream skill edit.

Moving the symlinks out of `.agents/skills` into a harness-specific path.
**Rejected**: it stops the five skills being shared across harnesses, which is
the only reason they are symlinked there.

## Architectural Decision

1. **Discovery rule.** A `.agents/skills` entry is rendered only when it
   carries a `SKILL.md` and its path resolves inside the repository root. An
   entry whose resolved path escapes the root is excluded, whether or not its
   target exists.
2. **Owner.** The rule is `discover_skills(source, root)` in
   `scripts/harness_skills.py`, returning the rendered names and a map of
   excluded name to symlink target. `build_inventory()` in
   `scripts/agent-harnesses.py` is its only discovery caller.
3. **Reporting.** `inventory --json` reports the excluded names as
   `skills.external`, and `generate` (including `--check`) prints one
   `skipped (source outside repo): ~/.agents/skills/<name> -> <target>` line per
   exclusion to stderr. Exclusion is never an error; exit status is unaffected.
4. **No adapters for out-of-repo skills.** The five symlinked skills get no
   `antigravity`/`cursor` wrappers and no `generated-paths.json` entries, in any
   environment. Clause 8 of
   [2026-09-07-adopt-conventional-docs](./2026-09-07-adopt-conventional-docs.md)
   no longer holds for them.
5. **Commands and agents are untouched.** `.claude/commands` and `.codex/agents`
   hold no out-of-repo symlinks, and `validate` pins their counts (28 commands,
   6 agents), so a dangling entry there fails loudly instead of drifting
   silently. The rule is not extended to them until that changes.

## Positions

- **Fail generation when `.agents/skills` holds an out-of-repo entry.**
  Rejected: it would block `just harness-generate` on a setup the maintainer
  chose deliberately.
- **Gitignore the five symlinks instead.** Rejected on its own: an untracked
  symlink still resolves locally, so `generate` would still render adapters no
  other checkout can reproduce. Only the discovery rule fixes that.
