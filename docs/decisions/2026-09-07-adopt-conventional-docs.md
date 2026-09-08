# Adopt Conventional Docs

## Issue

This repository's documentation is ungoverned: there is no fixed place for
architectural decisions, no branch-scoped record of in-flight plans, and no
rule for when a topic graduates from a scratch file into `docs/`. The
`conventional-docs` skill (`skills/conventional-docs/SKILL.md` in
`phatblat/conventional-docs`) codifies a documentation set — Charter, Design,
Decisions, Roadmap, Plan, Todo, Events, Changelog — with explicit graduation
thresholds and a commit-event vocabulary, and it is now installed at
`~/.agents/skills/conventional-docs` so every harness in this repository
discovers it. This decision adopts the convention here, chooses which
artifacts this single-maintainer, single-repository setup actually needs, and
records where each one lives.

## Status

This is a proposal that is **accepted**.

## Assumptions and Constraints

- This repository is rooted at `$HOME`, is single-maintainer, and has no
  release process: it is never tagged, published, or versioned.
- A dotfiles worktree under `~/.worktrees/dotfiles/<branch>` cannot host the
  live `~/.agents/skills` symlink omp reads, so this adoption is validated
  against the real `$HOME` checkout, not a worktree.
- `~/CLAUDE.md` is deliberately hand-authored Claude-specific guidance rather
  than an import of `~/AGENTS.md` (`.agentlink/config.toml`); this decision
  does not apply the convention's import idiom to it.
- `scripts/agent-harnesses.py` treats `.agents/skills/**` and
  `docs/agent-harnesses.{json,md}` / `docs/harness/**` as generator-owned; new
  Conventional Docs artifacts must not collide with those paths.
- No commit-message linter is wired up in this repository (`hk.pkl` has no
  commit-msg step; there is no commitlint config or `core.hooksPath`), so the
  event-commit vocabulary below is enforced by convention, not tooling.

## Argument

The clutter trigger fires at the repository root: dozens of tracked top-level
entries already exist (`README.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
`LICENSE.md`, `Brewfile`, `justfile`, `build.gradle.kts`, `bin/`, `docs/`,
`scripts/`, `tests/`, `crates/`, …), and `docs/` already holds nine documents
plus four subdirectories. A graduated Charter and a `docs/decisions/` log fit
that structure directly. Branch-scoped `PLAN.md`/`TODO.md` at the root are
**Chosen**: the convention gives them no graduated form, and they are deleted
before merge, so they never compete with the root's existing clutter.

Adopting the full artifact set (**Rejected**) — Roadmap, Design, Changelog —
would document capability this repository doesn't have: no ordered backlog
distinct from ad-hoc work, no single design surface (per-domain docs under
`docs/` already fill that role), and no releases to describe. Each is deferred
until the triggering condition exists, per the Architectural Decision below.

## Architectural Decision

1. **Graduated forms.** Artifacts live under `docs/`: `docs/charter.md` and
   `docs/decisions/YYYY-MM-DD-slug.md`.
2. **Branch-scoped artifacts stay at the root.** `~/PLAN.md` and `~/TODO.md`
   have no graduated form and are deleted before merge.
3. **Event vocabulary.** This repo announces `decision:`, `plan:`, and
   `todo:`. `release:` and `deploy:` are not adopted — the repo publishes
   nothing and cuts no versions.
4. **Subject-length exemption.** `.gitmessage` asks for a capitalized subject
   of ≤50 characters. Event commits are exempt: the id is the entire
   reference (e.g. `decision: propose 2026-09-07-adopt-conventional-docs` is
   52 characters), stay lowercase, and are capped at 72 characters.
5. **No changelog.** The repo has no releases and no downstream consumers, so
   no `CHANGELOG.md` is created.
6. **No Roadmap yet.** One is added when there is a real ordered backlog to
   record; `docs/charter.md`'s Artifacts table says so explicitly rather than
   shipping an empty file.
7. **No Design artifact.** `docs/` already carries per-domain design documents
   (`docs/agent-harnesses.md`, `docs/tooling-dimensions.md`,
   `docs/package-management.md`, `docs/functions.md`, `docs/harness/`);
   `docs/charter.md`'s Artifacts table records that split instead of
   duplicating it into a `docs/design.md`.
8. **Skill installation.** The skill is a symlink into the working checkout
   at `~/dev/agents/conventional-docs`
   (`~/.agents/skills/conventional-docs -> ~/dev/agents/conventional-docs/skills/conventional-docs`),
   matching the existing symlinked-skill pattern (`authoring-skills`,
   `recording-changes`, `semantic-versioning`, `setup-phatblat-skills`). Its
   generated `antigravity`/`cursor` adapters are committed, matching that same
   established pattern.

## Positions

- **Root `CHARTER.md`/`ROADMAP.md`.** Rejected: the clutter trigger fires
  here (see Argument), so graduated form is used from the start instead of
  starting at the root and migrating later.
- **Copy the skill directory into `.agents/skills/conventional-docs/` as real
  content**, the way `using-git-worktrees` does. Rejected while the
  convention is still moving: a copy forks the source and needs manual resync
  on every `SKILL.md` change; a symlink stays current for free.
- **Create a `CHANGELOG.md`.** Rejected: no releases, nothing to describe.
