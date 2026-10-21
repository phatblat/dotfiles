---
description: Split the most recent commit (or a specified commit) into two or more logical commits
category: workflow
model: haiku
allowed-tools: Bash(git:*), Bash(echo:*), Bash(grep:*), Bash(head:*), AskUserQuestion
---

Split a single git commit into two or more commits with distinct logical concerns.

## Overview

This command splits a commit without interactive rebase (`-i` is forbidden).
The technique: soft-reset the target commit back into the working tree, then
re-commit the files in logical groups.

## Arguments

Optional: the user may pass a commit ref (e.g. `HEAD~2`, `abc1234`).
Default target is `HEAD` (the most recent commit).

## Steps

### 1. Validate state

```bash
git rev-parse --abbrev-ref HEAD
git status --porcelain=v1
```

**Working tree must be clean.** If there are uncommitted changes, STOP and tell
the user to stash or commit them first.

### 2. Identify the target commit

If the user provided a ref, use it. Otherwise default to `HEAD`.

Show what's in it:
```bash
git show --stat <ref>
git show --name-only <ref> | tail -n +5
```

### 3. Propose the split

Analyse the files and group them by logical concern. Present the proposed
groups to the user with `AskUserQuestion` before touching any history:

- Group A: files for commit 1 (description)
- Group B: files for commit 2 (description)
- ...

Wait for confirmation. If the grouping is wrong, adjust and re-propose.

### 4. Soft-reset the target commit

If target is `HEAD`:
```bash
git reset HEAD~1
```

If target is an older commit, STOP — splitting non-HEAD commits requires
rebase and is outside this command's scope. Tell the user to first use
`git rebase` to bring the commit to HEAD if needed.

After reset, verify the files are back in the working tree:
```bash
git status --porcelain=v1
```

### 5. Re-commit each group

For each logical group in order:

```bash
git add <file1> <file2> ...
git commit -m "<type>(<scope>): <description>"
```

Follow the project's commit conventions (conventional commits:
`feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `build`).

Use a HEREDOC for multi-line messages:
```bash
git commit -m "$(cat <<'EOF'
type(scope): short description

- bullet detail
- bullet detail

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

### 6. Verify

```bash
git log --oneline -6
git status --porcelain=v1
```

Confirm working tree is clean and the new commits look correct.

Report with ✅ and show the resulting log.

## Constraints

- Never use `git rebase -i` (interactive mode forbidden)
- Never use `git reset --hard` (destructive — use soft reset only)
- Only supports splitting the most recent commit (HEAD)
- If the commit is already pushed to a shared remote, warn the user that
  force-push will be required after splitting and ask for confirmation
