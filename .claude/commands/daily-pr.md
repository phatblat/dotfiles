---
description: Start the daily dotfiles workflow — clean up old branches, create today's branch, open draft PR
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*), AskUserQuestion
category: workflow
---

# Daily Dotfiles Workflow

Set up today's daily branch, clean up previous daily branches, and ensure a draft PR exists.

## Instructions

### 1. Detect Context

Run a single combined command to gather all context:

```bash
remote=$(git remote | head -1)
today=$(date +%A | tr '[:upper:]' '[:lower:]')
today_date=$(date +%Y-%m-%d)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
current_branch=$(git branch --show-current)
echo "remote=${remote} today=${today} date=${today_date} default=${default_branch} current=${current_branch}"
```

Record all values for use in subsequent steps.

### 2. Prune Remote-Tracking Branches

Remove stale remote-tracking references (e.g., `phatblat/wednesday` lingering after the remote branch was deleted via PR merge):

```bash
git fetch ${remote} --prune
```

Report any pruned refs from the output (lines starting with ` - [deleted]`). This keeps `git branch -r` accurate before subsequent branch operations.

### 3. Check for Uncommitted Changes

```bash
git status --porcelain=v1
```

If the working tree is dirty:
- Tell the user what files are modified
- Ask whether to: **(a)** commit on the current branch first, **(b)** stash changes, or **(c)** abort
- Do NOT silently stash or discard changes
- Wait for user response before proceeding

### 4. Clean Up Previous Daily Branches

Check all seven weekday names: `monday tuesday wednesday thursday friday saturday sunday`

**Skip today's weekday name** — do not clean up today's branch.

For each remaining weekday that exists as a local branch (`git branch --list <weekday>`):

1. Query PR status:
   ```bash
   gh pr list --head "<weekday>" --state all --json number,state,mergedAt --jq '.[0] | "\(.number)|\(.state)|\(.mergedAt // "none")"'
   ```

2. Classify and act:
   - **PR merged** (`state=MERGED`):
     - Delete local branch: `git branch -D <weekday>`
     - Check if remote branch exists: `git ls-remote --heads ${remote} <weekday>`
     - If remote exists, delete it: `git push ${remote} --delete <weekday>`
     - Record as cleaned up
   - **PR open** (`state=OPEN`): Leave it. Warn: "Branch `<weekday>` has open PR #N — leaving it."
   - **PR closed but unmerged** (`state=CLOSED`): Leave it. Warn: "Branch `<weekday>` has closed-but-unmerged PR #N — leaving it."
   - **No PR found** (empty result): Leave it. Warn: "Branch `<weekday>` has no PR — leaving it."

### 5. Pull Latest Default Branch

Update the default branch without switching to it:

```bash
git fetch ${remote} ${default_branch}
```

### 6. Create or Switch to Today's Worktree

Determine the worktree path using the dotfiles convention:

```bash
worktree_path="${HOME}/.worktrees/dotfiles/${today}"
```

Check if today's branch/worktree already exists:

- **Worktree already exists** (check `git worktree list | grep "${worktree_path}"`): Report "Worktree for `${today}` already exists at `${worktree_path}`."
- **Branch exists locally but no worktree**: Create worktree from existing branch:
  ```bash
  git worktree add "${worktree_path}" ${today}
  ```
- **Branch exists only on remote** (check `git ls-remote --heads ${remote} ${today}`): Create worktree tracking remote:
  ```bash
  git worktree add "${worktree_path}" -b ${today} ${remote}/${today}
  ```
  Then fast-forward to avoid non-fast-forward rejections (e.g., when switching machines):
  ```bash
  git -C "${worktree_path}" fetch ${remote} ${today}
  git -C "${worktree_path}" merge --ff-only ${remote}/${today}
  ```
  If the fast-forward fails (local has diverged), warn the user and ask how to proceed rather than force-pushing.
- **Does not exist**: Create new branch and worktree from default branch:
  ```bash
  git worktree add "${worktree_path}" -b ${today} ${remote}/${default_branch}
  ```

**Immediately after creating the worktree**, ensure remote tracking is set up:

- **Branch is newly created (no remote)**: Push to establish tracking:
  ```bash
  git -C "${worktree_path}" push -u ${remote} ${today}:${today}
  ```

Then verify tracking:

```bash
git -C "${worktree_path}" branch -vv | grep "${today}"
```

This ensures tracking is established before any commits are made, not deferred to PR creation.

**Note:** All subsequent git operations for today's work should be run from within the worktree at `${worktree_path}`, or use `git -C "${worktree_path}"`.

### 7. Create Draft PR (Idempotent)

Check for an existing PR:

```bash
gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
```

- **PR exists**: Report the existing PR number and URL. Skip creation.
- **No PR**: Create one (branch was already pushed in step 5):
  ```bash
  gh pr create --draft --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
  ```

### 8. Report Summary

Output a summary like:

```
## Daily Setup Complete

Branch: sunday
PR: #278 (draft) — chore: sunday 2026-04-06

Pruned remote-tracking refs:
  - phatblat/tuesday

Cleaned up:
  - saturday (#277, merged) — deleted local + remote

Still around:
  - friday (#275, open) — left alone
```

If nothing was pruned, omit the "Pruned remote-tracking refs" section.

If nothing was cleaned up, report "No previous daily branches to clean up."

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Run twice same day | Step 6 switches to existing branch; Step 7 reports existing PR |
| Dirty working tree | Step 3 asks user before proceeding |
| Previous PR unmerged | Step 4 leaves branch with warning |
| Multi-day gap | All 7 weekday names are checked, not just yesterday |
| Remote branch already deleted | Step 4 checks `git ls-remote` before attempting delete |
| Worktree already exists for today | Step 6 reports existing worktree path |
| Already on default branch | Step 5 just fetches |
| Stale remote-tracking refs | Step 2 prunes them via `git fetch --prune` |
