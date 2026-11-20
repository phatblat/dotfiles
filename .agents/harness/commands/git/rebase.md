---
description: Rebase current branch onto a target branch using the optimal strategy, auto-resolving conflicts where safe
model: sonnet
allowed-tools: Bash(git:*), Read, Edit, AskUserQuestion
category: workflow
argument-hint: "[target-branch]"
---

# Git Rebase: Smart Branch Update

Rebase the current branch onto a target branch, automatically selecting the best strategy based on divergence analysis and automatically resolving conflicts the rules in Step 6 can decide (pausing only for genuine semantic collisions).

## Context Gathering

Collect all needed state in one pass:

!`git branch --show-current 2>/dev/null`
!`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || git config init.defaultBranch || echo "main"`
!`git status --porcelain=v1`

## Instructions

### 1. Resolve Branches

- **Subject branch**: current branch (from above)
- **Target branch**: `$ARGUMENTS` if provided, otherwise the detected default branch (from above)
- Abort immediately if subject branch == target branch and tell the user

### 2. Guard: Clean Working Tree

If `git status --porcelain=v1` shows any output, stop and tell the user:
> "Working tree is dirty. Commit or stash changes before rebasing."

### 3. Fetch & Update Target

```bash
git fetch origin
git fetch origin <target>:<target>   # fast-forward local target branch
```

If the fast-forward fails (target has diverged locally), stop and report.

### 4. Divergence Analysis

Run these in one bash call:

```bash
MERGE_BASE=$(git merge-base HEAD <target>)
echo "merge_base=$MERGE_BASE"
echo "subject_commits=$(git log $MERGE_BASE..HEAD --oneline | wc -l | tr -d ' ')"
echo "target_commits=$(git log $MERGE_BASE..<target> --oneline | wc -l | tr -d ' ')"
echo "subject_files=$(git diff --name-only $MERGE_BASE HEAD)"
echo "target_files=$(git diff --name-only $MERGE_BASE <target>)"
# Check if merge-base is on the target branch lineage
git merge-base --is-ancestor $MERGE_BASE <target> && echo "base_on_target=yes" || echo "base_on_target=no"
```

Compute overlap: files changed in both subject and target since merge-base.

### 5. Strategy Selection

Use this decision tree:

| Condition | Strategy |
|-----------|----------|
| `base_on_target=no` (branch cut from non-target branch) | **rebase --onto** |
| Otherwise | **simple rebase** |

Every strategy rebases `<subject>` in place: never create, switch, rename, or delete a branch. Branch switching and `git reset --hard` may be blocked in a main checkout, so avoid them. A large, overlapping divergence still uses simple rebase, which skips commits whose patch is already in `<target>` (rebase-merged or cherry-picked commits that got new hashes). Squash-merged commits are not skipped; they conflict or go empty and are handled in Step 6.

Display the analysis before proceeding:

```
Branch analysis:
  Subject:         <subject> (<N> commits ahead of merge-base)
  Target:          <target> (<N> commits since merge-base)
  Overlapping files: <N>
  Merge-base on target lineage: yes/no

Selected strategy: <strategy>
Reason: <one sentence>
```

Then proceed with the selected strategy.

---

### Strategy A: Simple Rebase

```bash
git rebase <target>
```

On success → go to Step 7.
On conflict → go to Step 6 (Conflict Handler).

---

### Strategy B: Rebase --onto

Determine `<old-base>`: the commit just before the subject branch diverged from its original base.

```bash
OLD_BASE=$(git merge-base HEAD <target>)
git rebase --onto <target> $OLD_BASE
```

Pass no branch argument: with a trailing `HEAD`, git rebases a detached HEAD and leaves `<subject>` where it was, and re-attaching it needs a branch switch the harness may block.

On success → go to Step 7.
On conflict → go to Step 6 (Conflict Handler).

---

### 6. Conflict Handler (automatic resolution)

When a conflict is detected mid-operation, **resolve it automatically and continue** — do not pause for conflicts the rules below can decide. The branch reflog and `rerere` (enabled) make every auto-resolution recoverable and auditable.

For each conflicted file (`git diff --name-only --diff-filter=U`):

1. **Recorded resolution:** if `rerere` already resolved it (no conflict markers remain), accept it as-is.
2. **Classify and resolve:**
   - **Machine-managed / filtered state** — files with a git `clean` filter (e.g. `.codex/*.config.toml` hook trust hashes, marketplace timestamps): `git checkout --ours -- <file>` so the working tree keeps its real state; the clean filter re-normalizes the committed blob on `git add`.
   - **Dependency / version bumps** — lockfiles, version pins, `mise`/package manifests: keep the **higher** version. If the incoming bump is already superseded upstream, resolve to ours (the patch will go empty in step 4).
   - **Deliberate config updates** — when the replayed commit's whole purpose is to set a value: `git checkout --theirs -- <file>` (take the incoming value).
   - **Generated artifacts:** regenerate from source instead of merging by hand, then stage the result.
   - **Non-overlapping additions:** keep both sides.
3. **Stage and verify:** `git add -- <file>`, then confirm no `<<<<<<<` / `=======` / `>>>>>>>` markers remain in it.
4. **Continue:** `GIT_EDITOR=true git rebase --continue` to preserve the original message. If the commit is now empty because its change was already upstream, `git rebase --skip`.

Repeat until the operation reports no remaining conflicts.

**Fallback — pause only when unsafe.** If a conflict is a genuine semantic collision in hand-written source that none of the rules above can decide, stop and report the file(s), both sides, and the resume commands — **never guess a semantic merge**. To roll back, use a form that does not switch branches or run `git reset --hard`, which a harness may block. While the rebase is stopped, abort it; this restores `<subject>` and the working tree to the pre-rebase commit:
```bash
git rebase --abort
```

`--abort` only works mid-rebase. To undo a rebase that already finished with a bad result (for example a wrong auto-resolution found in the audit below), move `<subject>` back to its pre-rebase commit in place. A finished rebase moves the branch exactly once, so its previous reflog entry `<subject>@{1}` is that commit; confirm with `git reflog -2 <subject>`, whose top entry must be the `rebase (finish)` one. With `HEAD` as the upstream there is nothing to replay, so the branch simply moves there:
```bash
git rebase --onto "<subject>@{1}" HEAD
```

When the operation finishes, report each auto-resolved conflict and the rule that was applied, so the user can audit the resolutions.

---

### 7. Fix Remote Tracking & Push

After rebase, the upstream tracking ref may point to the target branch instead of the subject branch. Always reset it explicitly:

```bash
git branch --set-upstream-to=origin/<subject> <subject>
```

Then force push with an explicit refspec to ensure tracking stays correct:

```bash
git push --force-with-lease -u origin <subject>:<subject>
```

Verify tracking is correct:

```bash
git branch -vv | grep '^\*'
```

The output must show `[origin/<subject> ...]` — if it shows the target branch name, tracking is wrong and must be fixed before proceeding.

### 8. Success Report

```
Rebase complete.
  Strategy used:   <strategy>
  Subject branch:  <subject>  (<N> commits on top of <target>)
  Tracking:        origin/<subject>
```

Note: rerere is enabled, so conflict resolutions from previous runs may have been applied automatically during Step 6.
