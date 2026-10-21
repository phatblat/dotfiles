---
description: Start the daily dotfiles workflow — layer today's branch on the current daily branch, clean up old branches, open a draft PR
model: sonnet
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*), AskUserQuestion, Skill
category: workflow
---

# Daily Dotfiles Workflow

Set up today's daily branch from the current daily branch, clean up older daily branches, and ensure a draft PR exists.

## Instructions

### 1. Detect Context

Run a single combined command to gather all context:

```bash
remote=$(git remote | head -1)
dow=$(date +%A | tr '[:upper:]' '[:lower:]')
if [ "$dow" = "saturday" ] || [ "$dow" = "sunday" ]; then today="weekend"; else today="$dow"; fi
today_date=$(date +%Y-%m-%d)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
current_branch=$(git branch --show-current)
source_branch=${current_branch}
echo "remote=${remote} dow=${dow} today=${today} date=${today_date} default=${default_branch} current=${current_branch} source=${source_branch}"
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

Check all branch names: `monday tuesday wednesday thursday friday weekend`

**Skip today's branch name** (`${today}`) and the captured source branch (`${source_branch}`). The source branch must remain available until today's branch has been created from it.

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

### 5. Prepare the Source Branch

Keep `${source_branch}` checked out. Do not switch to the default branch: new daily branches inherit the source branch's complete state.

Validate the source before continuing:

- **Daily branch** (`monday`, `tuesday`, `wednesday`, `thursday`, `friday`, or `weekend`): Use it as the source.
- **Default branch**: Use it as the fallback source when no daily branch is active.
- **Any other branch**: Ask whether to use that branch as the source or abort. Do not silently bring an unrelated feature branch into the daily chain.

If the source differs from today's branch, check whether that exact source branch exists on the remote. Treat the lookup status as a safety boundary:

- **Status `0`**: Fetch and fast-forward the remote source before branching.
- **Status `2`**: The remote source is absent; intentionally continue with the local source branch.
- **Any other status**: Report the lookup failure and stop the workflow before branching. Do not treat network, authentication, or remote errors as a missing branch.

```bash
if test "${source_branch}" != "${today}"; then
  source_remote_status=0
  git ls-remote --exit-code --heads "${remote}" "${source_branch}" >/dev/null 2>&1 || source_remote_status=$?

  case "${source_remote_status}" in
    0)
      git fetch "${remote}" "${source_branch}"
      git merge --ff-only "${remote}/${source_branch}"
      ;;
    2)
      echo "Source branch '${source_branch}' is absent from '${remote}'; continuing with the local source branch."
      ;;
    *)
      echo "Failed to inspect source branch '${source_branch}' on '${remote}' (git ls-remote status ${source_remote_status}); stopping before branching." >&2
      exit "${source_remote_status}"
      ;;
  esac
fi
```

If the fast-forward fails because the local and remote source branches diverged, warn the user and ask how to proceed. Do not merge, rebase, or force-push automatically.

### 6. Create or Switch to Today's Branch

Check if today's branch already exists:

- **Exists locally**: `git checkout "${today}"` — report "Branch `${today}` already exists. Switched to it."
- **Exists only on remote** (check `git ls-remote --heads "${remote}" "${today}"`): `git checkout -b "${today}" "${remote}/${today}"`
- **Does not exist**: `git checkout -b "${today}" "${source_branch}"` — creates from the captured current daily branch

For a newly created branch, report: "Created `${today}` from `${source_branch}`."

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

### 7. Create Draft PR (Idempotent)

Check for an existing PR:

```bash
gh pr list --head "${today}" --state open --json number,url --jq '.[0] | "\(.number)|\(.url)"'
```

- **PR exists**: Report the existing PR number and URL. Skip creation.
- **No PR**: Choose the branch that today's branch must be ahead of. A newly layered branch compares against its source so it receives a unique marker commit even before the source PR merges. A same-day rerun compares against the default branch because `${source_branch}` and `${today}` are the same branch:
  ```bash
  comparison_branch=${default_branch}
  if [ "${source_branch}" != "${today}" ]; then
    comparison_branch=${source_branch}
  fi
  git rev-list --count "${comparison_branch}..${today}"
  ```
  If the count is `0`, create an empty commit so GitHub can diff the branches:
  ```bash
  git commit --allow-empty -m "chore: start ${today} ${today_date}"
  git push ${remote} ${today}:${today}
  ```
  Then create the PR using `--draft` and `--assignee @me` per the `pr-style` skill:
  ```bash
  gh pr create --draft --base "${default_branch}" --assignee @me --title "chore: ${today} ${today_date}" --body "Daily dotfiles branch for ${today}, ${today_date}."
  ```
  The branch is layered on `${source_branch}`, but the PR still targets `${default_branch}`. Until the source PR merges, the new PR shows the cumulative daily state; afterward, its diff naturally shrinks to the newer changes. Daily PRs use a fixed title/body format, not the full `pr-style` body template. Labels are skipped for daily branches.

### 8. Report Summary

Output a summary like:

```
## Daily Setup Complete

Branch: weekend
Source: friday
PR: #278 (draft) — chore: weekend 2026-04-05

Pruned remote-tracking refs:
  - phatblat/tuesday

Cleaned up:
  - monday (#277, merged) — deleted local + remote

Still around:
  - thursday (#275, open) — left alone
```

If nothing was pruned, omit the "Pruned remote-tracking refs" section.

If nothing was cleaned up, report "No previous daily branches to clean up."

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Run twice same day | Step 6 switches to existing branch; Step 7 reports existing PR |
| Dirty working tree | Step 3 asks user before proceeding |
| Previous PR unmerged | Step 4 leaves branch with warning |
| Multi-day gap | All 6 branch names are checked (mon-fri + weekend), not just yesterday |
| Remote branch already deleted | Step 4 checks `git ls-remote` before attempting delete |
| Current branch is the previous daily branch | Step 4 preserves it; Steps 5–6 fast-forward it and create today from its HEAD |
| Current source branch already merged | Keep it as today's source; a later run can clean it up |
| Already on today's branch | Step 5 does not use a separate source; Step 6 is a no-op |
| Already on default branch | Use the default branch as the fallback source |
| Current branch is not daily or default | Ask before inheriting it; do not proceed silently |
| Stale remote-tracking refs | Step 2 prunes them via `git fetch --prune` |
| No commits unique to today's branch | Step 7 compares with the source branch and creates an empty marker commit before PR creation |
