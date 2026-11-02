---
name: using-git-worktrees
description: Explains the ~/.worktrees/<path-key>/<branch> worktree convention, the dotfiles-repo opt-in, and what a dotfiles worktree cannot validate. Use to understand or explain worktree layout and its constraints; use the git-worktree skill to actually create, switch to, or delete one.
---

# Git Worktrees

**Announce at start:** "Using using-git-worktrees skill for the ~/.worktrees/ layout and constraints."

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

## Dotfiles Repo

The dotfiles repo is an ordinary clone at `~/dev/dotfiles` (path key `dev-dotfiles`), so its worktrees follow the core convention (`~/.worktrees/dev-dotfiles/<branch>`) with no `--allow-home` opt-in. `$HOME` is not the repo: `mise dot` deploys the primary checkout's tracked files into `$HOME` as absolute symlinks (spec: `.config/mise/conf.d/dotfiles.toml`), so live `$HOME` follows whatever the primary checkout has checked out. A post-checkout/merge/commit/rewrite git hook re-runs `mise dot apply` there; linked worktrees never deploy.

Promote changes to live `$HOME` by merging or checking them out in `~/dev/dotfiles`. `just home-deploy <ref>` pins `$HOME` to a commit (detached checkout of the primary) and `just home-live` returns to the branch it left. `just test` remaps `HOME` to the checkout itself, so run it from any worktree.

**Detection:** Resolve via `git rev-parse --path-format=absolute --git-common-dir` (strip the trailing `/.git`), not `--show-toplevel` — `--show-toplevel` returns the *worktree's* root, so it misfires from inside any worktree. If the resolved path is `~/dev/dotfiles`, you are in the dotfiles repo.

### What a Dotfiles Worktree Does Not Cover

- **Live shell startup.** `wt shell <branch>` exercises `.config/zsh/**` (via `$ZDOTDIR`) and `.config/nushell/**` (via `$XDG_CONFIG_HOME`) for one nested session; running terminals keep sourcing the files linked from the primary checkout.
- **Intentionally-absolute symlinks.** `bin/plistbuddy`, `bin/vi`, and `bin/vim` point at system/Homebrew binaries outside the repo; `.config/iterm2/AppSupport` points at untracked app state. These stay absolute by design and are excluded from hk's `symlinks` step (`scripts/check-symlinks.sh`, run via `just lint`).
- **3 ancestor-discoverable configs.** `.config/mise/config.toml`, `.editorconfig`, and `.envrc` are found by tools that walk up from cwd. Because a dotfiles worktree lives beneath the real `$HOME`, such a tool can discover the real `$HOME`'s copy instead of the worktree's own. `wt verify`/`wt shell` warn on stderr only when the two copies actually differ.

## Creating, Switching, Deleting

Use the `git-worktree` skill (`/git:worktree`). It owns the executable
procedure and the session rebase; this skill owns the layout and constraints
it enforces.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Any repo under `~` | `~/.worktrees/<path-key>/<branch>` |
| Dotfiles repo (`~/dev/dotfiles`) | Same as any repo: `~/.worktrees/dev-dotfiles/<branch>` |
| Branch created | Push with `-u` and explicit refspec immediately |
| PR merged/closed | `git worktree remove` the path |
| Project-local `.worktrees/` exists | IGNORE IT — still use `~/.worktrees/` |

## Never

- Create worktrees inside the repo (no project-local `.worktrees/` or `worktrees/`)
- Use `~/.config/superpowers/worktrees/` or any other location
- Skip remote tracking setup after branch creation
- Let `push.autoSetupRemote` be the only tracking mechanism
- Update a local branch ref from a different worktree if that branch is checked out elsewhere; use `origin/<branch>` until the owning worktree is free

## Integration

**Called by:** Any skill or workflow needing an isolated workspace
**Pairs with:** branch-finish for cleanup after work is complete, git-worktree for the executable actions
