---
name: plan-worktree
description: Update a WIP implementation plan by inserting a Phase 0 that creates a git branch and worktree, switches to it, and moves any WIP work from the current working copy into the new worktree. Use when asked to add worktree setup to a plan, when invoked as /plan:worktree, or when a plan should execute in an isolated checkout.
---

# Plan Worktree

**Announce at start:** "Using plan-worktree skill to add a Phase 0 worktree setup to <plan>."

Takes a WIP plan (default: `PLAN.md` at the repo root, or the path the user names) and prepends a **Phase 0: Worktree Setup** that isolates plan execution in a git worktree, carrying over any uncommitted work already in progress.

## Arguments

- Plan path (default `PLAN.md` at repo root).
- Optional branch name. Default: derive from the plan title slug (e.g. `ben/<slug>` per repo convention); confirm with the user if ambiguous.
- Optional base branch. Default: the repo's default branch, unless the WIP work clearly builds on the current branch — then use the current branch and say so.

## Workflow

### 1. Read the plan

Read the plan file. Note:

- Whether a Phase 0 / worktree-setup task already exists — if so, report and stop (idempotent).
- The existing task/phase numbering so the inserted phase renumbers nothing: title the new section **Phase 0** and leave all existing phases/tasks untouched.
- The plan's task format (checkbox steps, `**Files:**` blocks) so Phase 0 matches it.

### 2. Assess WIP state

```bash
git status --porcelain=v1
git branch --show-current
```

- **Dirty tree**: Phase 0 must move the changes. Use `git stash push -u -m "wip: <plan-slug>"` in the current checkout, create the worktree, then `git stash pop` inside the new worktree. (Stash-then-pop is the only safe cross-worktree move; never copy files by hand.)
- **Clean tree**: Phase 0 skips the stash steps — note that in the step text so an executor on a dirty tree still knows what to do (keep the stash steps, marked "skip if tree is clean").
- **Untracked plan file**: if `PLAN.md` itself is untracked, the `-u` flag covers it; call this out in the step.

### 3. Insert Phase 0

Insert immediately after the plan header block (after the `---` following Goal/Architecture/Tech Stack), before the first existing phase/task. Match the plan's existing step style. Required content:

```markdown
## Phase 0: Worktree Setup

**Files:**
- Modify: none (workspace setup only)

- [ ] **Step 1: Stash any WIP in the current checkout** (skip if `git status --porcelain` is empty)

Run: `git stash push -u -m "wip: <plan-slug>"`
Expected: `Saved working directory and index state …` (includes untracked files, e.g. PLAN.md if untracked)

- [ ] **Step 2: Create branch and worktree via the git-worktree skill**

REQUIRED SUB-SKILL: `git-worktree`

```bash
git branch <branch> <base-branch>   # skip if <branch> already exists
wt switch <branch>                  # add --allow-home for dotfiles
```

`wt switch` has no base option: it checks out an existing local branch, so the `git branch` line is what applies `<base-branch>`. If `<branch>` already existed, it is used as is and the report says so instead of naming a base. Creates the worktree under `~/.worktrees/<path-key>/<branch>` and prints the path. From here, every command runs with the worktree as cwd; every file path is absolute under it; every subagent prompt states the worktree path (subagents inherit the parent cwd).

- [ ] **Step 3: Restore the WIP into the worktree** (skip if Step 1 was skipped)

Run: `git stash pop` (inside the worktree)
Expected: the stashed changes reappear in `git status`; drop the stash entry.

- [ ] **Step 4: Rebase the session onto the worktree**

Follow the git-worktree skill's Session Rebase Protocol: bind all tool calls to the worktree path (part A), and print the one-line harness command for the user (omp: `/move <wt_path>`; claude: `/add-dir <wt_path>`). Do not block on the user running it.

- [ ] **Step 5: Verify baseline**

Run the repo's fast check (e.g. `just check` or `wt verify <branch>`) to confirm the worktree starts green before Phase 1 changes anything.
```

Substitute real values for `<plan-slug>`, `<branch>`, `<base-branch>`. If the repo is dotfiles, include `--allow-home` in the `wt` invocation.

### 4. Report

- Plan file updated, branch name, base branch (or "existing branch, base unchanged").
- Whether stash steps are live (dirty tree) or conditional (clean tree).
- Reminder: Phase 0 delegates mechanics to the `git-worktree` skill; path derivation never goes in the plan prose.

## Never

- Never renumber or edit existing phases/tasks — Phase 0 is inserted, nothing else moves.
- Never hardcode `~/.worktrees/...` paths in the plan beyond referencing the `wt` CLI's printed path; `wt path <branch>` is the single source of truth.
- Never use `git worktree add` directly in plan steps — the `git-worktree` skill owns creation and session rebasing.
- Never add a second Phase 0 if one already exists.
