---
name: git-rebase
description: |-
  Rebase branches and resolve merge conflicts. Use when rebasing onto main/target,
  resolving conflicts during rebase or cherry-pick, recovering from failed rebases,
  or when the user mentions "rebase", "merge conflict", "conflict resolution",
  "rebase --onto", "cherry-pick conflict", "diverged branch", or "rebase abort".
---

# Git Rebase & Conflict Resolution

Reference skill for rebase strategy selection and conflict resolution. The `/git:rebase` command handles the operational flow — this skill provides the decision framework and conflict resolution patterns.

## Strategy Selection

Analyze divergence before choosing a strategy:

```bash
MERGE_BASE=$(git merge-base HEAD <target>)
subject_commits=$(git log $MERGE_BASE..HEAD --oneline | wc -l | tr -d ' ')
target_commits=$(git log $MERGE_BASE..<target> --oneline | wc -l | tr -d ' ')
overlap=$(comm -12 <(git diff --name-only $MERGE_BASE HEAD | sort) <(git diff --name-only $MERGE_BASE <target> | sort) | wc -l | tr -d ' ')
git merge-base --is-ancestor $MERGE_BASE <target> && on_target="yes" || on_target="no"
```

### Decision Tree

| Condition | Strategy | Why |
|-----------|----------|-----|
| `target_commits` >= 20 AND `overlap` >= 3 | **cherry-pick** | Heavy divergence with file overlap — replaying commits one-by-one gives finer control over conflicts |
| `on_target=no` (branch cut from non-target) | **rebase --onto** | Branch base isn't on target lineage — need to transplant the commit range |
| Otherwise | **simple rebase** | Default — clean replay onto updated target |

### When to Prefer Merge Instead

Rebase is not always the right tool. Suggest `git merge` when:

- The branch is shared with other developers (rebase rewrites history they depend on)
- The branch has been force-pushed multiple times and teammates have local copies
- The conflict surface is enormous (50+ conflicting files) — merge preserves both histories

Always ask before choosing merge over rebase since the user explicitly requested a rebase.

## Conflict Resolution

### Principles

1. **Understand both sides first** — read the conflict markers and trace what each side intended
2. **Prefer the semantic intent over the literal text** — if both sides changed the same function differently, the resolution may be neither version verbatim
3. **Rerere is enabled** — git records conflict resolutions and auto-applies them on repeat encounters. Check `git rerere status` to see if a resolution was auto-applied
4. **One file at a time** — resolve, stage, verify, move on

### Reading Conflict Markers

```
<<<<<<< HEAD (or Updating)
  code from the commit being replayed (ours during rebase)
||||||| parent of <sha>    ← only with diff3 style
  common ancestor version
=======
  code from the target branch (theirs during rebase)
>>>>>>> <target>
```

**Rebase inverts ours/theirs**: During `git rebase`, "ours" is the target branch (what you're rebasing onto) and "theirs" is your commit being replayed. This is the opposite of merge.

### Resolution Strategies by Conflict Type

| Conflict Type | Resolution Approach |
|--------------|---------------------|
| **Both sides edited same lines** | Read both changes, synthesize the intent into a combined version |
| **One side deleted, other edited** | Determine if the deletion or the edit should win based on commit messages |
| **File renamed on one side, edited on other** | Accept rename, apply edits to the new path |
| **Both sides added at same location** | Keep both additions in logical order |
| **Lock file conflicts** (package-lock, yarn.lock, Cargo.lock) | Accept the target version, then regenerate: `npm install`, `cargo generate-lockfile`, etc. |
| **Generated file conflicts** (proto, schema) | Accept target version, regenerate from source |
| **Formatting-only conflicts** | Accept either side, then run the project formatter |

### Resolution Workflow

```bash
# 1. See which files are conflicted
git diff --name-only --diff-filter=U

# 2. For each conflicted file, examine the conflict
git diff <file>

# 3. After editing the file to resolve
git add <file>

# 4. Continue the operation
git rebase --continue    # or: git cherry-pick --continue
```

### Lock File Resolution

Never manually edit lock files. Instead:

```bash
# Accept the target branch version
git checkout --theirs <lockfile>
git add <lockfile>

# After rebase completes, regenerate
npm install          # package-lock.json
pnpm install         # pnpm-lock.yaml
cargo generate-lockfile  # Cargo.lock
uv lock              # uv.lock
```

## Recovery

### Abort a Rebase

```bash
git rebase --abort
```

Restores the branch to its exact state before the rebase started.

### Restore from Backup

The `/git:rebase` command creates a `.bak` branch before rebasing:

```bash
git reset --hard <branch>.bak
git branch -D <branch>.bak   # clean up after restoring
```

### Reflog Recovery

If no backup branch exists:

```bash
# Find the pre-rebase state
git reflog show <branch> | head -10

# Reset to the commit before the rebase
git reset --hard <branch>@{N}
```

### Stuck in a Rebase

```bash
# Check if a rebase is in progress
ls .git/rebase-merge/ 2>/dev/null || ls .git/rebase-apply/ 2>/dev/null

# See what commit is being applied
cat .git/rebase-merge/current-commit 2>/dev/null

# Options:
git rebase --abort     # give up entirely
git rebase --skip      # skip this commit (loses its changes)
git rebase --continue  # after resolving conflicts
```

## Safety Rules

- **Always create a backup branch before rebasing** (the `/git:rebase` command does this automatically)
- **Never rebase commits that have been pushed to a shared branch** without coordinating with other developers
- **Use `--force-with-lease`** instead of `--force` when pushing rebased branches — it fails if someone else pushed in the meantime
- **Verify tracking after rebase** — rebase can silently change the upstream tracking ref
