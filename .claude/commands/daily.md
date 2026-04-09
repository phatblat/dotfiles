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

### 2. Check for Uncommitted Changes

```bash
git status --porcelain=v1
```

If the working tree is dirty:
- Tell the user what files are modified
- Ask whether to: **(a)** commit on the current branch first, **(b)** stash changes, or **(c)** abort
- Do NOT silently stash or discard changes
- Wait for user response before proceeding

### 3. Clean Up Previous Daily Branches

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

### 4. Switch to Default Branch and Pull Latest

Only switch if not already on the default branch:

```bash
git checkout ${default_branch}
git pull ${remote} ${default_branch}
```

### 5. Create or Switch to Today's Branch

Check if today's branch already exists:

- **Exists locally**: `git checkout ${today}` — report "Branch `${today}` already exists. Switched to it."
- **Exists only on remote** (check `git ls-remote --heads ${remote} ${today}`): `git checkout -b ${today} ${remote}/${today}`
- **Does not exist**: `git checkout -b ${today}` — creates from the default branch

**Immediately after creating or switching to today's branch**, ensure remote tracking is set up:

- **Branch is newly created (no remote)**: Push to establish tracking:
  ```bash
  git push -u ${remote} ${today}:${today}
  ```
- **Branch already exists on remote**: Fetch and fast-forward to avoid non-fast-forward rejections (e.g., when switching machines):
  ```bash
  git fetch ${remote} ${today}
  git merge --ff-only ${remote}/${today}
  ```
  If the fast-forward fails (local has diverged), warn the user and ask how to proceed rather than force-pushing.

Then verify tracking:

```bash
git branch -vv | grep "${today}"
```

This ensures tracking is established before any commits are made, not deferred to PR creation.

### 6. Create Draft PR (Idempotent)

Check for an existing PR:

```bash
gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
```

- **PR exists**: Report the existing PR number and URL. Skip creation.
- **No PR**: Create one (branch was already pushed in step 5):
  ```bash
  gh pr create --draft --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
  ```

### 7. Report Summary

Output a summary like:

```
## Daily Setup Complete

Branch: sunday
PR: #278 (draft) — chore: sunday 2026-04-06

Cleaned up:
  - saturday (#277, merged) — deleted local + remote

Still around:
  - friday (#275, open) — left alone
```

If nothing was cleaned up, report "No previous daily branches to clean up."

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Run twice same day | Step 5 switches to existing branch; Step 6 reports existing PR |
| Dirty working tree | Step 2 asks user before proceeding |
| Previous PR unmerged | Step 3 leaves branch with warning |
| Multi-day gap | All 7 weekday names are checked, not just yesterday |
| Remote branch already deleted | Step 3 checks `git ls-remote` before attempting delete |
| Already on today's branch | Step 4 skips checkout to default; Step 5 is a no-op |
| Already on default branch | Step 4 skips checkout, just pulls |
