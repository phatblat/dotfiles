---
description: Rebase current branch onto a target branch using the optimal strategy
allowed-tools: Bash(git:*), AskUserQuestion
category: workflow
argument-hint: "[target-branch]"
---

# Git Rebase: Smart Branch Update

Rebase the current branch onto a target branch, automatically selecting the best strategy based on divergence analysis.

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

### 4. Create Backup Branch

```bash
git branch <subject>.bak
```

Report: `Created backup branch <subject>.bak`

If `.bak` already exists, ask the user whether to overwrite it or abort.

### 5. Divergence Analysis

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

### 6. Strategy Selection

Use this decision tree:

| Condition | Strategy |
|-----------|----------|
| `target_commits` ≥ 20 **AND** overlapping files ≥ 3 | **cherry-pick** |
| `base_on_target=no` (branch cut from non-target branch) | **rebase --onto** |
| Otherwise | **simple rebase** |

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

On success → go to Step 8.
On conflict → go to Step 7 (Conflict Handler).

---

### Strategy B: Rebase --onto

Determine `<old-base>`: the commit just before the subject branch diverged from its original base.

```bash
OLD_BASE=$(git merge-base HEAD <target>)
git rebase --onto <target> $OLD_BASE HEAD
```

On success → go to Step 8.
On conflict → go to Step 7 (Conflict Handler).

---

### Strategy C: Cherry-pick

1. Collect commits to replay (oldest first):
   ```bash
   git log --reverse --format="%H" <merge-base>..HEAD
   ```

2. Create a temp branch from target:
   ```bash
   git checkout -b <subject>__cherrypick__ <target>
   ```

3. Cherry-pick each commit in order:
   ```bash
   git cherry-pick <sha>
   ```
   On conflict → go to Step 7 (Conflict Handler) before continuing.

4. On success of all picks:
   ```bash
   git branch -D <subject>            # delete old branch
   git branch -m <subject>__cherrypick__ <subject>  # rename to original name
   git checkout <subject>
   ```

On complete success → go to Step 8.

---

### 7. Conflict Handler

When a conflict is detected mid-operation, pause and ask the user:

> "Conflict detected in `<file(s)>`.
>
> How would you like to proceed?
>
> **a)** Abort — restore from `<subject>.bak` and clean up
> **b)** Pause here — resolve conflicts manually, then run `git rebase --continue` (or `git cherry-pick --continue`) yourself
>
> Enter a or b:"

**If user chooses a (Abort):**

For rebase:
```bash
git rebase --abort
```
For cherry-pick:
```bash
git cherry-pick --abort
git checkout <subject>
git branch -D <subject>__cherrypick__  # if it exists
```
Then restore:
```bash
git checkout <subject>   # if not already on it
git reset --hard <subject>.bak
```
Report: "Restored `<subject>` from backup. Branch is unchanged."

**If user chooses b (Pause):**

Report the exact commands the user needs to resolve and continue, e.g.:
```
Paused at conflict. Resolve the conflicts in:
  - <file1>
  - <file2>

Then run:
  git add <files>
  git rebase --continue    # or: git cherry-pick --continue

The backup branch <subject>.bak is still available if you need to roll back:
  git reset --hard <subject>.bak
```
Then stop — do not continue until the user resumes.

---

### 8. Success Report

```
Rebase complete.
  Strategy used:   <strategy>
  Subject branch:  <subject>  (<N> commits on top of <target>)
  Backup branch:   <subject>.bak  (kept — delete when satisfied)

To clean up backup:
  git branch -D <subject>.bak

To push (force required since history was rewritten):
  git push --force-with-lease origin <subject>
```

Note: rerere is enabled, so conflict resolutions from previous runs may have been applied automatically during Step 7.
