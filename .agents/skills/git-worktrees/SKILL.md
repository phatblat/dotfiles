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

The dotfiles repo (rooted at `~`) needs an explicit opt-in before using worktrees: `wt --dotfiles <branch>` (or `wt --test <branch>` / `wt --shell <branch>`). Without one of those flags, `wt` refuses. The real limitation is narrower than "cannot be tested": interactive shell *startup* (`.zshenv`, `.zshrc`, `.zprofile`, and the functions autoloaded from `.config/zsh/functions/`) is only exercised from the real `$HOME`, so validating startup changes still needs a branch switch there. Everything else — linting, tests, the harness gates — is verifiable from a worktree via `wt --test <branch>`, mirroring how `.github/workflows/lint.yml` already remaps `HOME` to run `just lint`/`just test` in CI.

**Detection:** Resolve via `git rev-parse --path-format=absolute --git-common-dir` (strip the trailing `/.git`), not `--show-toplevel` — `--show-toplevel` returns the *worktree's* root, so it misfires from inside any worktree. If the resolved path equals the home directory, you are in the dotfiles repo.

### What a Dotfiles Worktree Does Not Cover

- **Interactive shell startup.** `.zshenv`, `.zshrc`, `.zprofile`, and the functions autoloaded from `.config/zsh/functions/` are only exercised by the real, running shell at `$HOME`. Validate startup changes with a branch switch there, not a worktree.
- **4 intentionally-absolute symlinks.** `bin/plistbuddy`, `bin/vi`, and `bin/vim` point at system/Homebrew binaries outside `$HOME`; `.config/iterm2/AppSupport` points at untracked app state. These stay absolute by design and are excluded from `just lint-symlinks`.
- **3 ancestor-discoverable configs.** `.config/mise/config.toml`, `.editorconfig`, and `.envrc` are found by tools that walk up from cwd. Because a dotfiles worktree lives beneath the real `$HOME`, such a tool can discover the real `$HOME`'s copy instead of the worktree's own. `wt --test`/`wt --shell` warn on stderr only when the two copies actually differ.

## Creation Steps

### 1. Verify Not Dotfiles Repo

```bash
repo_root=$(git rev-parse --path-format=absolute --git-common-dir)
repo_root=${repo_root%/.git}
if [ "$repo_root" = "$HOME" ]; then
  echo "NOTE: Dotfiles repo. Use 'wt --dotfiles <branch>' (or 'wt --test <branch>' / 'wt --shell <branch>') for an opt-in worktree — see Dotfiles Exception above."
  exit 1
fi
```

### 2. Guard Against Submodule False Positive

Git submodules also have `GIT_DIR != GIT_COMMON_DIR`, which looks identical to a worktree.
Before concluding you're already in a worktree, rule out submodules:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
superproject=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
if [ -n "$superproject" ]; then
  echo "NOTE: Inside a git submodule (superproject: $superproject). Proceeding as normal repo."
fi
```

### 3. Derive Path Key

```bash
repo_root=$(git rev-parse --path-format=absolute --git-common-dir)
repo_root=${repo_root%/.git}
path_key=$(echo "$repo_root" | sed "s|^$HOME/||" | tr '/' '-')
```

### 4. Create Worktree

```bash
worktree_path="$HOME/.worktrees/$path_key/$BRANCH_NAME"
git worktree add "$worktree_path" -b "$BRANCH_NAME"
```

### 5. Set Up Remote Tracking Immediately

Every new branch MUST have remote tracking before any commits:

```bash
cd "$worktree_path"
git push -u origin "$BRANCH_NAME:$BRANCH_NAME"
```

Verify with `git branch -vv`.

### 6. Run Project Setup

Auto-detect and run appropriate setup:

```bash
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f pyproject.toml ] && uv sync
[ -f go.mod ] && go mod download
```

### 7. Verify Clean Baseline

Run project-appropriate tests. If tests fail, report failures and ask whether to proceed.

### 8. Report

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
| Dotfiles repo (`~` is repo root) | Needs `wt --dotfiles`/`--test`/`--shell` opt-in; refuses otherwise |
| Branch created | Push with `-u` and explicit refspec immediately |
| PR merged/closed | `git worktree remove` the path |
| Project-local `.worktrees/` exists | IGNORE IT — still use `~/.worktrees/` |

## Never

- Create worktrees inside the repo (no project-local `.worktrees/` or `worktrees/`) — except dotfiles worktrees, which necessarily live at `~/.worktrees/dotfiles/<branch>` inside the `$HOME` tree; that path is `.gitignore`d so it never dirties `git status` in `$HOME`
- Use `~/.config/superpowers/worktrees/` or any other location
- Create a dotfiles worktree without the explicit opt-in flag (`wt --dotfiles`/`--test`/`--shell`)
- Use a dotfiles worktree to validate `.zshrc`, `.zshenv`, `.zprofile`, or `.config/zsh/functions/**` — those only run from the real `$HOME`
- Run bare `just`/`just check` inside a dotfiles worktree instead of `wt --test <branch>`, which sets up the `$HOME`/mise/git-config remapping that makes the gate meaningful
- Skip remote tracking setup after branch creation
- Let `push.autoSetupRemote` be the only tracking mechanism
- Update a local branch ref from a different worktree if that branch is checked out elsewhere; use `origin/<branch>` until the owning worktree is free

## Integration

**Called by:** Any skill or workflow needing an isolated workspace
**Pairs with:** branch-finish for cleanup after work is complete
