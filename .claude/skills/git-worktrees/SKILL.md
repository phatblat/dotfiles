---
name: git-worktrees
description: Create and manage git worktrees using the global ~/.worktrees/ convention. Use when starting feature work that needs isolation, before executing implementation plans, or any time a git worktree is needed.
---

# Git Worktrees

**Announce at start:** "Using git-worktrees skill to set up an isolated workspace at ~/.worktrees/."

## Core Convention

ALL worktrees go under `~/.worktrees/`, namespaced by repo location to avoid collisions:

```
~/.worktrees/<path-key>/<branch-name>
```

Where `<path-key>` is the repo root relative to `~` with `/` replaced by `-`.

| Clone location | Path key | Example worktree |
|---|---|---|
| `~/dev/apple/foo` | `dev-apple-foo` | `~/.worktrees/dev-apple-foo/feature-auth` |
| `~/dev/_GETDITTO/bar` | `dev-_GETDITTO-bar` | `~/.worktrees/dev-_GETDITTO-bar/fix-crash` |

## Dotfiles Exception

The dotfiles repo (rooted at `~`) MUST NOT use worktrees. Shell config, tool settings, and autoload functions are loaded from the main working tree. Changes in a worktree cannot be tested. Use regular branch switching for dotfiles.

**Detection:** If `git rev-parse --show-toplevel` returns the home directory, STOP and explain why worktrees cannot be used.

## Creation Steps

### 1. Verify Not Dotfiles Repo

```bash
repo_root=$(git rev-parse --show-toplevel)
if [ "$repo_root" = "$HOME" ]; then
  echo "ERROR: Dotfiles repo cannot use worktrees. Use branch switching instead."
  exit 1
fi
```

### 2. Derive Path Key

```bash
repo_root=$(git rev-parse --show-toplevel)
path_key=$(echo "$repo_root" | sed "s|^$HOME/||" | tr '/' '-')
```

### 3. Create Worktree

```bash
worktree_path="$HOME/.worktrees/$path_key/$BRANCH_NAME"
git worktree add "$worktree_path" -b "$BRANCH_NAME"
```

### 4. Set Up Remote Tracking Immediately

Every new branch MUST have remote tracking before any commits:

```bash
cd "$worktree_path"
git push -u origin "$BRANCH_NAME:$BRANCH_NAME"
```

Verify with `git branch -vv`.

### 5. Run Project Setup

Auto-detect and run appropriate setup:

```bash
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && uv sync
[ -f go.mod ] && go mod download
```

### 6. Verify Clean Baseline

Run project-appropriate tests. If tests fail, report failures and ask whether to proceed.

### 7. Report

```
Worktree ready at ~/.worktrees/<path-key>/<branch>
Tests passing (N tests, 0 failures)
Ready to implement <feature-name>
```

## Cleanup

After merging or closing a PR:

```bash
git worktree remove ~/.worktrees/<path-key>/<branch>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Any repo under `~` | `~/.worktrees/<path-key>/<branch>` |
| Dotfiles repo (`~` is repo root) | REFUSE worktree, use branch switching |
| Branch created | Push with `-u` and explicit refspec immediately |
| PR merged/closed | `git worktree remove` the path |
| Project-local `.worktrees/` exists | IGNORE IT — still use `~/.worktrees/` |

## Never

- Create worktrees inside the repo (no project-local `.worktrees/` or `worktrees/`)
- Use `~/.config/superpowers/worktrees/` or any other location
- Create a worktree for the dotfiles repo
- Skip remote tracking setup after branch creation
- Let `push.autoSetupRemote` be the only tracking mechanism

## Integration

**Called by:** Any skill or workflow needing an isolated workspace
**Pairs with:** finishing-a-development-branch for cleanup after work is complete
