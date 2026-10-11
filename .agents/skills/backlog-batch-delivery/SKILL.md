---
name: backlog-batch-delivery
description: "Plan, order and deliver a batch of backlog items (e.g. every High item) in a Conventional Docs repo, one decision, branch, worktree, draft PR, review and merge per item. Use when asked to work through the backlog, implement all items of a priority, or sequence several backlog items end to end."
---

# Backlog batch delivery

For a repo that follows Conventional Docs (`docs/backlog/`, `docs/decisions/`, `PLAN.md`, `TODO.md`, `docs/events.md`). Read the `conventional-docs` skill (`~/.agents/skills/conventional-docs/SKILL.md`) and the repo's `AGENTS.md` and `docs/events.md` first; they win over anything here. Derived from a session that delivered eight High items plus a release and a deploy.

Two phases: **investigate and plan** (no code, ends with an approved plan), then **deliver** (one item at a time, same pipeline each).

## One owner per worktree

Before touching a branch or worktree, check that nobody else is driving it: `git ls-remote --heads origin '*<slug>'`, `git log -3` and `gh pr list --head <branch>`. A duplicated or forked session (for example one opened to write a skill) shares the worktree with the original. If commits, a PR or a `TODO.md` you did not write appear, stop editing, report, and leave uncommitted files alone. Never run the same item's pipeline twice.

## Phase 1: Investigate and plan

1. **Enumerate the surface.** List the items (`just backlog list <priority>` or `ls docs/backlog`). Read each item whole, plus every decision it links. Put each in the todo list, plus any release or deploy step the user asked for.
2. **Treat each item as a hypothesis, not a spec.** Backlog items rot. For every numeric or factual claim, check it against code, git history, the database or the live system, and record the verdict. Typical finds:
   - evidence tied to an archived account, environment or commit, so the item's premise has moved;
   - a figure that was superseded by later work, so the item cites a stale baseline;
   - "no such rows" claims that the data contradicts;
   - a proposed mechanism that does not match the code, such as a timer that also includes fill polling because the call returns after the wait.
   Write the corrections into the decision record, not only into chat. Name each as a "gap found and revised".
3. **Probe external facts empirically.** Entitlements, plan tiers, API coverage, repo visibility, collaborators: run a read-only probe (`gh api`, a data-API request with the staging keys). Do not infer from docs.
4. **Ask the user only about real tradeoffs.** Batch the questions, give 2-5 options with a recommendation, and say what each rejected option costs. Fold the answers into the plan as "decisions already made". Do not ask what code or config can answer.
5. **Treat a new requirement as its own item.** If the investigation exposes a prerequisite the backlog does not hold (a hold time before an exit, a missing instrument), give it its own section, decision and PR, and place it before its consumers.
6. **Order the work.** Write a dependency graph and a shared-surface table: which files, functions, tables or docs two or more items touch, and how each collision resolves. Ordering rules that held:
   - docs-only and policy items go first, because they unblock or settle questions for the rest;
   - an item that produces something another consumes (a table, a function, a number) goes before the consumer;
   - the item whose result changes a later item's behaviour lands alone, so before/after numbers are attributable;
   - an item gated on a measurement goes last, with the branch rule written mechanically in advance (`if X >= 1.0 then A else B`), so no question is needed mid-run;
   - release and deploy go after everything; deploy once.
   Where a proposed decision record links to a backlog item that will be deleted, plan the in-place link edit.
7. **Pin stop conditions in the plan.** Examples: a claim in a backlog item that fails to reproduce, a collaborator who is not the owner, a failed entitlement probe. A stop condition means stop and ask, not improvise.
8. **Write the plan to a plan file and submit it for approval** through the harness's plan-approval step (in omp: `local://<slug>-plan.md`, submitted via `xd://propose`). Re-submit when it changes. The plan carries, per item: branch, decision slug, gaps found, decision clauses, build steps with file anchors, tests, verification commands, inbound links to rewrite.

## Phase 2: Deliver (per item, in plan order)

1. **Claim.** `git pull --rebase`, then `git ls-remote --heads origin '*<slug>'`. A hit means someone else is on it: stop and ask. Then create the worktree (`wt switch <branch>`) and push the branch immediately. Run every later command with the worktree as its working directory (the shell tool's `cwd` parameter where it has one); never `cd`. In a fresh worktree run `uv sync` and `npm ci --ignore-scripts` (the link checker needs `node_modules`), and `git lfs pull` if the item needs fixture data.
2. **Decision.** Write the record with every clause and revision from the plan; its body is frozen at accept. Commit `decision: propose <id>` with Status `awaiting review`, then change only that line to `accepted` and commit `decision: accept <id>`. Later fixes go in `## Errata` only. Decision records never link to backlog items. An extension decision opens its Issue with the standard "extends" sentence, and the extended record gets an erratum (or an in-place line if still proposed). `lint-docs` requires `## Errata` to come after `## References`, so a frozen record that has no References section needs one added (a link to the new record) in the same commit as its first erratum.
3. **Plan and todo.** `PLAN.md` committed alone as `plan: start <id>`. `TODO.md` committed alone as `todo: sync`. To edit PLAN.md later without a work commit, use `git commit --fixup=<plan commit>` and `GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash origin/main`, before the first push of that history or with `--force-with-lease`.
4. **Build.** Delegate code to one subagent per item (in omp: `task`) with a self-contained brief: absolute worktree path, files, exact API, tests, acceptance commands, and "do not commit, do not touch docs, do not edit the other checkout". Afterwards check `git status` in the main checkout is clean (a subagent once edited the wrong checkout), read the diff yourself, and fix or re-dispatch. You write the decision, design, CHANGELOG, erratum and backlog deletion.
   - Commit one logical change per commit, each with the repo's required trailer.
   - In the same PR: update `docs/design.md`, add a `CHANGELOG.md [Unreleased]` line citing the decision, delete the backlog file, and rewrite inbound links.
5. **Local gates, in CI's form.** `just lint`, `just lint-docs`, `just lint-links`, `just lint-markdown`, `just lint-commits origin/main HEAD`, and `just test` (Bazel). Do not stop at pytest. Known traps:
   - a new test import needs its dep in `BUILD.bazel`; pytest passes and Bazel fails with `ModuleNotFoundError`;
   - commit body lines over 100 characters fail commitlint (wrap at about 96);
   - Markdown lines over 120 characters fail `lint-markdown`; put long log formats in a fenced block;
   - `just` recipes take positional arguments, not `name=value`;
   - env vars exported by the shell (`.env` via mise) can make unit tests fail that pass in CI, such as feed or threshold overrides; confirm by running the test on the unmodified branch before blaming the change;
   - run `ruff format` on test files subagents wrote.
   Run slow suites in the background and carry on; do not poll.
6. **Smoke the changed path.** Run the real thing where one exists (a benchmark against the staging stack, a backtest before and after). For a claim of "results unchanged", diff the two JSON outputs, excluding wall-clock fields.
7. **Draft PR.** Use `pr-create` and `pr-style`: `<type>(<scope>): <desc>` of at most 70 characters, a Summary, a Changes list, and an Evidence section that says what was and was not exercised.
8. **Review by a subagent that cannot edit.** Give it the PR number, the full head SHA, the worktree and the decision path. Require only numbered findings, each followed by a `blob/<sha>/<path>#L<a>-L<b>` URL. If the reviewer model is unavailable, retry with a general agent told it is a reviewer. **Validate every finding against the code** and drop wrong ones with a one-line reason. In practice most findings are real (a stale reference, a timing flaw in a multi-order path) and some are half wrong. Post only the valid text.
9. **Post and resolve.** `pr-post-review-findings` (it skips the daily-note step if the note is absent), then fix, commit, push, reply in the thread (never edit the original comment) and resolve it. Look the thread id up by the first comment's `databaseId` in `reviewThreads`; going through `node_id` failed.
10. **CI.** `gh pr checks <n> --watch --fail-fast=false`, in the background. On failure, run `ci-fix`.
11. **Close out.** `git rm PLAN.md`, commit `plan: done <id>`; `git rm TODO.md`, commit `todo: clear`; push; wait for CI again. Then `gh pr ready`, then `pr-merge` with the repo's method (merge commit where history uses them; an empty `reviewDecision` is not a blocker without branch protection). Then `git pull --prune --rebase` in the main checkout and remove the worktree (`wt remove` may say it is not registered when the PR flow already removed it; confirm with `git worktree list`).
12. **Next item** from freshly pulled `main`. Update the todo list when each item merges.

## After the batch

- **Release**: its own branch, one `release: vX.Y.Z` commit that renames `[Unreleased]`, bumps every version file (and regenerates lockfiles), then PR, review, merge, tag, push the tag, watch the release run.
- **Deploy**: once, after the tag. First re-run the entitlement or health probe that the deploy depends on. Then run the deploy recipe, run smoke checks (containers up, env values, banner line, new log lines), and record it as a `deploy: <env> vX.Y.Z` commit in the format of the previous deploy commit, via its own PR.

## Orchestrator discipline

- One batch per approved plan; the plan is the source of truth and the inline copy is authoritative until it is compressed.
- Parallelize across items only when the shared-surface table shows no collision; otherwise serialize and rebase.
- A decision that turns out to be wrong after accept is never edited: add an erratum or write a new decision.
- File follow-up work as `docs/backlog/<slug>.md` (with `Priority:`), not in the roadmap and not in decision bodies.
- Finish each session with `git pull --rebase` and `git push`.
