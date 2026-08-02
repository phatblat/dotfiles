# Handoff: ci-fix skill

**Created:** 2026-08-02T13:16:24Z
**Repository:** `/Users/phatblat`
**Branch:** `thursday`
**Base / HEAD:** `main` / `a9c710caa31739c65668dfc67b87bf392f738393`
**Status:** modified: `.gitignore`; untracked: `.codex/skills/`, `.config/opencode/skills/` — **pre-existing changes from an unrelated task in progress this session (a `parity` CI fix). Do not stage, commit, or revert these as part of implementing this handoff.**

## Goal

Implement `ci-fix` as a **user-invocable skill in the shared harness** (`.agents/skills/ci-fix/`), not a per-harness slash command. It must be generated across Claude, Codex, OpenCode, Antigravity, and Cursor by `scripts/agent-harnesses.py`, following exactly the pattern already established by the existing `handoff` skill (`.agents/skills/handoff/SKILL.md` → `NATIVE_SKILL_ADAPTERS` → generated adapters in `.claude/skills/`, `.codex/skills/`, `.config/opencode/skills/`, plus generic wrapper adapters for antigravity/cursor).

Behavior the skill must implement (already designed, see **Decisions Made**):
- Invoked with an optional GitHub Actions job URL (e.g. `.../actions/runs/<id>/job/<id>?pr=<n>`) — investigate and fix that one job.
- Invoked with no arguments — find the current branch's PR, enumerate failing CI checks, triage root cause(s), fix, verify locally, then hand off to `/git:push`.

## Start Here

> You are continuing the work described in this handoff. First run the
> verification commands in **Current State**, read the listed context files,
> then execute **Recommended Next Steps**. Preserve the recorded decisions;
> revisit them only if new evidence invalidates an assumption. Ask the human
> only the blocking questions in **Open Questions**.

## Current State

- **Completed:** A 4-agent parallel brainstorm (architect, critic, devops-expert, general-purpose/research — via the `brainstorm` skill) on the design of a `ci:fix` capability, triggered by a real incident this session: the `parity` GitHub Actions job failed because generated skill-adapter files (`.codex/skills/handoff/...`, `.config/opencode/skills/handoff/...`) were silently `.gitignore`d and never committed. Findings were synthesized and presented to the user in-conversation (not yet written to a file before this handoff — this document is the first durable capture). No skill code has been written yet.
- **In progress (unrelated, do not conflate):** the same session is separately mid-fix on the actual `parity` failure — `.gitignore` has been edited to add `!.codex/skills/**`/`!.codex/skills/` and `!.config/opencode/skills/**`/`!.config/opencode/skills/` negations, `python3 scripts/agent-harnesses.py generate` has been run (untracked files now visible to git), and `python3 scripts/agent-harnesses.py validate` passes locally. A full `just check` (via `just test`, 498 bats tests) was running in the background at handoff time to confirm before pushing that fix — check `git log` / `gh pr checks` on `thursday`'s PR to see if it landed before resuming.
- **Verification:** `python3 scripts/agent-harnesses.py validate` → pass (exit 0), run directly this session. `just lint` → pass. `just check-spelling` → pass. `just test` (498 bats tests, includes newly-added `tests/agent-harnesses.bats` and `tests/shell-paths.bats`) → was still running at handoff time (in progress, ~90/498 passed, no failures observed so far; slow due to per-process-exec overhead from SentinelOne endpoint security serializing every `exec()` on this machine — see `~/.claude/projects/-Users-phatblat/memory/project_sentinelone_exec_stall.md` — this is expected slowness, not a hang).
- **Resume commands:**
  ```bash
  git -C /Users/phatblat status --short --branch
  git -C /Users/phatblat log --oneline -5
  python3 /Users/phatblat/scripts/agent-harnesses.py validate
  gh pr checks --repo phatblat/dotfiles 396
  ```

## Decisions Made

| Decision | Rationale | Do not pursue |
| --- | --- | --- |
| Ship as a shared **skill** (`.agents/skills/ci-fix/`), not a `.claude/commands/ci/fix.md` command | User explicitly wants it user-invocable across the whole shared harness like `handoff`, not Claude-only | A Claude-only command under `.claude/commands/ci/` |
| Never parallelize the **fix/write** step; always serialize through one agent in the main working tree | All 4 brainstorm agents converged on this. `isolation: 'worktree'` (if a `Workflow`-style tool is used) prevents mid-edit corruption but does not resolve conflicts — it only relocates them to a merge step, which is worse than serializing at this repo's scale | Parallel fix-application with worktree isolation as the default path |
| Investigate all failing jobs' logs **together in one shared context**, not one subagent per job | Splitting investigation across isolated agent contexts is exactly what would hide a shared root cause — the real incident (one `.gitignore` gap breaking `parity`, plausibly also `lint`) is the textbook case this would miss. Repo has only 3 CI jobs total (`parity`, `lint`, `test` — confirmed by reading `.github/workflows/*.yml`), so per-job fan-out solves a throughput problem that doesn't exist at this scale | Spawning one investigator subagent per failing job as the default/v1 behavior |
| Compose the existing `gha-checks` and `gha-log-reader` skills for discovery/log-fetch rather than reimplementing `gh` calls | Both already exist in `~/.claude/skills/` and do PR-check triage and log diagnosis with an allowed/blocked `gh` command list and a "confirm before fix" pattern | Reimplementing raw `gh run view`/`gh api` log-fetching logic from scratch |
| Cheap root-cause correlation signals, ranked: same script/command invoked > shared file path in error output > diff-touched-path overlap with a job's known input surface > specific shared error substring. Discard generic signals (bare exit code, generic "Error" text) | Confirmed by reading actual CI logs during the real incident this session; devops-expert and critic agents independently ranked signals the same way | Clustering by exit code alone or by matching failing-step name (this repo's 3 jobs are independent scripts with no shared step name — this signal essentially never fires here) |
| Do **not** build general clustering/parallel-fix infrastructure for v1 | At N=3 jobs with a solo maintainer and small scoped diffs, one root cause per push is overwhelmingly the common case; clustering machinery solves for enterprise-monorepo-scale failure patterns this repo won't hit | Building the architect agent's fuller signature-matching + LLM-arbitration clustering system as the *default* path (keep it as a documented rare-escalation fallback only, gated behind "triage genuinely can't unify the failures") |
| Local `just check` passing is a fast pre-push sanity check, **not** the completion criterion. The real gate is push → poll `gh pr checks`/`gh run view` until previously-failing jobs go green | `lint` and `parity` jobs run on `ubuntu-latest`; only `test` matches local macOS. This repo's own CLAUDE.md documents known GNU/BSD coreutils gaps (`timeout`/`gtimeout` not installed locally) and this session's own `verification.md` rule forbids claiming completion without running *the* verification command — for a CI fix, that's CI itself | Declaring the `ci-fix` skill "done" (or any fix it produces "done") on local pass alone |
| Commit fixes via `/git:commit` (never hand-composed messages), grouped logically; push via `/git:push`; never auto-merge | Existing hard rules in this repo/session (global CLAUDE.md, `pr-merge.md`) | Having the skill hand-compose commit messages or invoke `gh pr merge` |

## Relevant Context

- `~/.agents/skills/handoff/SKILL.md` — the structural template to mirror exactly (frontmatter shape, `NATIVE_SKILL_ADAPTERS` registration, generated-adapter fan-out). This is the single best reference for "what does a user-invocable shared skill look like in this repo."
- `~/scripts/agent-harnesses.py` — the generator/validator. Key points for the next agent:
  - `NATIVE_SKILL_ADAPTERS = {"handoff"}` at line 55 — add `"ci-fix"` here.
  - `render_claude_skill`/`render_codex_skill`/`render_codex_skill_policy`/`render_opencode_skill` (lines ~866–907) — study these to understand what transform, if any, is applied per harness; confirm whether `ci-fix` needs any harness-specific adjustments (e.g. Codex's `agents/openai.yaml` policy file).
  - `command_generate`/`command_validate` (lines ~267–390) — the `--check`/`validate` flow that must pass after adding the new skill; this is what the `parity` CI job runs.
  - **Gitignore trap already hit once this session**: any new generated output directory under `.codex/*` or `.config/opencode/*` needs a matching `!path/**` / `!path/` negation added to `.gitignore`, or CI's `parity` job will fail identically to the incident that prompted this whole design exercise. The negations added this session (`!.codex/skills/**`, `!.config/opencode/skills/**`) are **directory-generic** — they should already cover a new `ci-fix` subdirectory under `.codex/skills/ci-fix/` and `.config/opencode/skills/ci-fix/` without further edits, but **verify this with `git status --short` after running `generate`** before assuming it's covered.
- `~/.claude/skills/gha-checks/SKILL.md` — PR check-status triage; step 0 of the new skill should invoke this.
- `~/.claude/skills/gha-log-reader/SKILL.md` — read-only per-job log diagnosis, allowed/blocked `gh` command list, phased root-cause output, "confirm before fix" dialog. Compose this for the log-fetch/triage step; reuse its confirm-before-fix pattern rather than inventing a new one.
- `~/.github/workflows/agent-harness-parity.yml` and `~/.github/workflows/lint.yml` — the actual 3 CI jobs (`parity` on `ubuntu-latest`; `lint` and `test` in `lint.yml`, `test` on `macos-latest`) this skill's default heuristics were tuned against. Re-read these if the CI topology has changed since 2026-08-02.
- Four brainstorm agent transcripts (this session, not separately saved to disk): `arch-cifix`, `critic-cifix`, `devops-cifix`, `research-cifix`. Their full text is in this session's conversation history; this handoff's **Decisions Made** table is the durable extraction. If the next agent has access to this session's transcript, re-reading the raw agent reports may surface nuance not captured here (e.g. the architect agent's fuller escalation-path algorithm, kept only as a summary above).

## Recommended Next Steps

1. Resolve **Open Questions** below (naming, invocation mode, portability vs. hardcoding) — via `AskUserQuestion` if picked up interactively, or reasonable defaults with the choice flagged in the commit/PR description if run autonomously.
2. Write `.agents/skills/ci-fix/SKILL.md` (the canonical source), modeled on `handoff/SKILL.md`'s structure: frontmatter (`name: ci-fix`, `description: ...`), a Rules section, and a numbered Workflow section encoding the algorithm from **Decisions Made**: (a) resolve target (arg = job URL, or no-arg = current branch's PR via `gha-checks`), (b) fetch failing logs via `gha-log-reader` sequentially in one context, (c) triage using the ranked cheap signals, (d) fix serially in the main working tree, (e) fast targeted local check while iterating, (f) full `just check` once before push, (g) `/git:commit` then `/git:push`, (h) poll `gh pr checks` and report real (not local-only) status.
3. Add `"ci-fix"` to `NATIVE_SKILL_ADAPTERS` in `~/scripts/agent-harnesses.py` (line 55).
4. Run `python3 ~/scripts/agent-harnesses.py generate`, then `git status --short` to confirm the new `.claude/skills/ci-fix/`, `.codex/skills/ci-fix/`, `.config/opencode/skills/ci-fix/` files are tracked (not silently gitignored — see the trap noted above).
5. Run `python3 ~/scripts/agent-harnesses.py validate` and `just check` to confirm parity and no regressions.
6. Commit via `/git:commit` (logical grouping: this should be its own commit, separate from the unrelated in-progress `parity`/`.gitignore` fix noted in **Current State** — confirm that other fix has already landed on `thursday` first, or coordinate commit order so `git diff` is unambiguous about which change is which).
7. Push via `/git:push`; do not merge (no `/pr:merge` invocation) without the user's explicit separate request.

## Open Questions

- [ ] **Naming convention:** existing skills in `.agents/skills/` use plain kebab-case (`handoff`), while `.claude/commands/` uses colon-namespaced paths (`pr:create`, `git:commit`). Should the skill be named `ci-fix` (kebab, matching `handoff`) or something else? This handoff assumes `ci-fix`. Blocks: the exact directory name and all generated adapter paths.
- [ ] **Invocation mode:** should `ci-fix` be manual-invocation-only like `handoff` (`disable-model-invocation: true`, triggered explicitly via `$ci-fix` or an explicit user request), or should it auto-trigger on natural-language cues like "CI failed", "the build is broken", "fix the checks"? Blocks: the skill's frontmatter and whether it needs trigger-phrase documentation.
- [ ] **Confirm-before-fix gate:** should `ci-fix` always show the user a diff/plan and wait for confirmation before writing fixes (reusing `gha-log-reader`'s existing pattern), or only when the fix touches files outside a low-risk allowlist (e.g. `.gitignore`, generated artifacts)? Blocks: whether the skill can ever be fully autonomous end-to-end.
- [ ] **Portability vs. repo-specific heuristics:** the devops-expert brainstorm agent found this repo's job→input-surface map small enough to hardcode (`parity`→generated dirs+`.gitignore`, `lint`→source+config, `test`→bats+fixtures) for better triage accuracy — but hardcoding it makes the skill less portable to the *other* harnesses this shared-skill system targets, if they ever get their own CI. Should `ci-fix` ship with this repo's map baked in (fast, accurate, but dotfiles-specific), or stay fully generic and re-derive the map each run from `.github/workflows/*.yml` (slower, more portable)? This handoff has no recommendation — flagging as unresolved.
- [ ] **Escalation-path completeness:** the architect agent's fuller design (signature-matching clustering + LLM-arbitration for ambiguous cases + parallel-fix-with-worktree-isolation above ~4 file-disjoint clusters) was explicitly deferred as "build only if triage genuinely can't unify failures." Should v1 include even a stub/placeholder for this escalation path, or should it be added later only if a real multi-cause-failure incident is observed? This handoff recommends deferring it entirely (no stub) but flags it as a judgment call, not a settled fact.
- [ ] Has the separate, in-progress `parity`/`.gitignore` fix (see **Current State**) already been committed and pushed by the time this handoff is picked up? If not, resolve/coordinate with it first — it is a prerequisite for `just check`/`validate` passing cleanly on a fresh checkout.

## Confidence

**Plan completeness:** medium (55%).

The *design* (algorithm, decisions, rationale) is high-confidence — it was independently converged on by 4 separate expert brainstorm passes plus one real incident as ground truth. What's genuinely unresolved is *packaging*: no `SKILL.md` content has been drafted, none of the four Open Questions above have a decided answer, and the skill has not been generated, validated, or tested end-to-end against a real failing CI run. Evidence that would raise confidence: a first draft of `.agents/skills/ci-fix/SKILL.md`, a successful `generate`+`validate` cycle, and one real dry run against an actual failing PR check.

## Estimate

- **Scope:** small–medium
- **Story points:** 3
- **Engineering time:** 1–2 hours for a first working draft; more if the confirm-before-fix UX or the portability question needs iteration
- **Agent effort:** roughly 30–60k tokens (one focused session: draft SKILL.md, wire generator, validate, commit)
- **Main risk:** the four Open Questions are genuine product decisions, not implementation details — guessing wrong on invocation mode or portability could mean a rewrite rather than a tweak

## Suggested Agent Structure

One agent, sequential. This is not parallelizable work: it's a single coherent skill file plus one generator registration, gated by decisions that need to be made in order (naming → invocation mode → algorithm details → implementation). Not warranted: a multi-agent team would add coordination overhead for what is fundamentally one file and one config-line change.
