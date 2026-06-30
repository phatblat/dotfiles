---
name: git-split
description: Split the most recent git commit into multiple logical commits without interactive rebase. Use when invoked as `$git-split` or when the user asks to split HEAD into smaller commits.
---

# git-split

Split `HEAD` into two or more logical commits by soft-resetting it into the working tree and recommitting groups.

## Workflow

1. Validate state:

   ```bash
   git rev-parse --abbrev-ref HEAD
   git status --porcelain=v1
   ```

   Stop if the working tree is dirty.

2. Identify target:

   - Default target is `HEAD`.
   - If the user provides an older commit, stop. This skill does not use interactive rebase; ask the user to first move that commit to `HEAD`.

3. Inspect target:

   ```bash
   git show --stat HEAD
   git show --name-only HEAD
   ```

4. Propose logical groups before changing history. Ask for confirmation if grouping is ambiguous or if the commit appears already pushed.

5. Soft reset:

   ```bash
   git reset HEAD~1
   git status --porcelain=v1
   ```

6. For each confirmed group:

   ```bash
   git add <files>
   git commit -m "<type>(<scope>): <description>"
   ```

   Follow repo commit conventions and keep each commit to one coherent concern.

7. Verify:

   ```bash
   git log --oneline -6
   git status --porcelain=v1
   ```

8. Report the resulting commits. If the original commit was pushed, explain that a force-with-lease push is required.

Constraints: never use `git rebase -i`; never use `git reset --hard`.
