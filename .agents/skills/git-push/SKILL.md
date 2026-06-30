---
name: git-push
description: Intelligently push the current git branch to its remote with safety checks. Use when invoked as `$git-push` or when the user asks to push committed work.
---

# git-push

Push commits to the remote repository with branch and working-tree safety checks.

## Workflow

1. Gather status in one pass:

   ```bash
   git status --porcelain=v1
   git branch -vv
   git remote -v
   git log --oneline @{u}..HEAD 2>/dev/null
   ```

2. Evaluate safety:

   - If there are uncommitted changes, warn and do not push unless the user explicitly asked to push anyway.
   - If the branch has no upstream, push with `git push -u <remote> <branch>:<branch>`.
   - If the branch is behind its upstream, stop and recommend `git pull --rebase` or a branch-specific rebase workflow.
   - If the branch has diverged, stop and explain the divergence.
   - If a force push is required, warn strongly and require explicit confirmation before `git push --force-with-lease`.

3. Push:

   - Tracked branch: `git push`
   - New branch: `git push -u <remote> <branch>:<branch>`

4. Report only the final result:

   ```text
   ✅ Pushed <branch> to <remote>
   <remote output summary>
   ```

For protected default branches, remind the user that PR flow is preferred.
