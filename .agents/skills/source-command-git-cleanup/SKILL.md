---
name: "source-command-git-cleanup"
description: "Delete local branches that have been merged or whose PRs are closed/stale"
---

# source-command-git-cleanup

Use this skill when the user asks to run the migrated source command `git-cleanup`.

## Command Template

# Git Cleanup: Remove Stale Local Branches

Analyze local branches, classify them by status, and offer to delete merged/stale ones.

## Instructions

### 1. Guard: Not on a Detached HEAD

Run `git branch --show-current`. If empty, stop and tell the user:
> "You're in detached HEAD state. Check out a branch first."

Record the current branch name — it must never be deleted.

### 2. Detect Default Branch

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || git config init.defaultBranch || echo "main"
```

Record as `<default-branch>`. It must never be deleted.

### 3. List Local Branches with Metadata

```bash
git for-each-ref --format='%(refname:short)|%(committerdate:short)|%(committerdate:relative)' refs/heads/ | sort -t'|' -k2
```

Exclude `<default-branch>` and the current branch from candidates.

### 4. Check Merge and PR Status

For each candidate branch:

1. **Ancestor check**: `git merge-base --is-ancestor <branch> <default-branch>` — if yes, it's merged (rebase-merged or fast-forwarded).

2. **PR status**: Query GitHub for the branch's PR state:
   ```bash
   gh pr list --head "<branch>" --state all --json number,state,mergedAt --jq '.[0] | "\(.number)|\(.state)|\(.mergedAt // \"n/a\")"'
   ```

### 5. Classify Branches

Place each branch into one of these categories:

| Category | Criteria |
|----------|----------|
| **Active** | Open PR, or current branch |
| **Merged** | PR state is MERGED, or branch is ancestor of default branch |
| **Closed** | PR state is CLOSED (not merged) |
| **Stale** | No PR found and not merged |
| **Protected** | Default branch or current branch — never delete |

### 6. Present Summary

Display a table grouped by category:

```
## Branch Cleanup Summary

### Active (will keep)
| Branch | Age | PR |
|--------|-----|----|
| ...    | ... | .. |

### Merged (safe to delete)
| Branch | Age | PR |
|--------|-----|----|
| ...    | ... | .. |

### Closed (safe to delete)
| Branch | Age | PR |
|--------|-----|----|
| ...    | ... | .. |

### Stale — no PR (safe to delete)
| Branch | Age | PR |
|--------|-----|----|
| ...    | ... | .. |
```

If there are no branches to delete, report "All branches are active or protected. Nothing to clean up." and stop.

### 7. Confirm Deletion

Ask the user:

> "Delete **N** branches (M merged, X closed, Y stale)? [yes/no/pick]"
>
> - **yes** — delete all merged + closed + stale branches
> - **no** — abort, keep everything
> - **pick** — let user specify which categories or individual branches to delete

### 8. Remove Worktrees for Confirmed Branches

Before deleting branches, check for associated worktrees:

```bash
git worktree list --porcelain
```

For each confirmed branch, check if a worktree references it (the `branch refs/heads/<branch>` line in porcelain output). If so, remove the worktree first:

```bash
git worktree remove <worktree-path>
```

If removal fails (dirty worktree), warn the user and skip that branch — do not force-remove without explicit approval.

### 9. Delete Confirmed Branches (skip any whose worktree removal was declined)

```bash
git branch -D <branch1> <branch2> ...
```

Delete in a single command for efficiency. Do NOT use `-d` (lowercase) since squash-merged branches won't be detected as merged by git.

### 10. Report Results

List deleted branches and remaining local branches:

```
Deleted N branches:
  - branch1
  - branch2

Remaining local branches:
  - main
  - feature/current-work
  - ...
```
