---
name: purge-worktrees
description: Remove git worktrees whose associated PRs have been merged or closed
model: sonnet
allowed_tools:
  - Bash
allowed_prompts:
  - tool: Bash
    prompt: "git rev-parse"
  - tool: Bash
    prompt: "git worktree"
  - tool: Bash
    prompt: "gh pr"
---

<default_to_action>
Run the check and prune in one pass. Do not ask for confirmation before removing worktrees whose PRs are merged or closed. Report what was removed and what was kept.
</default_to_action>

# Purge Merged Worktrees

Cleans up git worktrees in the current repo whose pull requests have already been merged or closed. Worktrees with open PRs, no associated PR, or uncommitted changes are preserved.

## Workflow

### 1. Verify we are inside a git worktree

```bash
git rev-parse --is-inside-work-tree
```

If this fails or returns anything other than `true`, print `Not in a git worktree; nothing to do.` and stop.

### 2. List all worktrees for the repo

```bash
git worktree list --porcelain
```

Parse the output to extract each worktree's path and branch. Identify the current worktree (the one whose path matches the current working directory) — it must never be removed.

### 3. Resolve PR status for each sibling worktree

For each worktree other than the current one, query GitHub for PRs whose head branch matches:

```bash
gh pr list --state all --head "<branch>" --json number,state,title,url --limit 5
```

Classify each worktree:

- **Merged/Closed PR** → candidate for removal.
- **Open PR** → keep.
- **No PR at all** → keep (may be in-progress work not yet pushed).
- **Main worktree / detached HEAD / unparseable branch** → keep.

Batch the `gh pr list` calls in parallel where possible to keep the command fast.

### 4. Remove eligible worktrees

For each worktree marked for removal:

```bash
git worktree remove "<path>"
```

If `git worktree remove` fails (e.g., uncommitted changes, locked worktree), record the error and keep moving — do not use `--force`.

### 5. Report

Print two grouped lists:

```
Removed:
  <path>  (branch, PR #<n> <state>)
  ...

Kept:
  <path>  (branch, reason: open PR #<n> | no PR | current worktree | removal failed: <error>)
  ...
```

Finish with a one-line summary: `Removed N worktree(s), kept M.`

## Rules

- **Never** remove the current worktree.
- **Never** remove a worktree that has an open PR.
- **Never** remove a worktree without an associated PR — treat "no PR found" as in-progress work.
- **Never** pass `--force` to `git worktree remove`. If removal fails, report and skip.
- Match PR state case-insensitively; `gh` returns `MERGED`, `CLOSED`, `OPEN`.

$ARGUMENTS
