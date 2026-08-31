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

## Dotfiles Exception

The dotfiles repo (rooted at `~`) needs an explicit opt-in before using worktrees: `wt --dotfiles <branch>` (or `wt --test <branch>` / `wt --shell <branch>`). Without one of those flags, `wt` refuses. The real limitation is narrower than "cannot be tested": interactive shell *startup* (`.zshenv`, `.zshrc`, `.zprofile`, and the functions autoloaded from `.config/zsh/functions/`) is only exercised from the real `$HOME`, so validating startup changes still needs a branch switch there. Everything else — linting, tests, the harness gates — is verifiable from a worktree via `wt --test <branch>`, mirroring how `.github/workflows/lint.yml` already remaps `HOME` to run `just lint`/`just test` in CI.

**Detection:** Resolve via `git rev-parse --path-format=absolute --git-common-dir` (strip the trailing `/.git`), not `--show-toplevel` — `--show-toplevel` returns the *worktree's* root, so it misfires from inside any worktree. If the resolved path equals the home directory, you are in the dotfiles repo.

### What a Dotfiles Worktree Does Not Cover

- **Interactive shell startup.** `.zshenv`, `.zshrc`, `.zprofile`, and the functions autoloaded from `.config/zsh/functions/` are only exercised by the real, running shell at `$HOME`. Validate startup changes with a branch switch there, not a worktree.
- **4 intentionally-absolute symlinks.** `bin/plistbuddy`, `bin/vi`, and `bin/vim` point at system/Homebrew binaries outside `$HOME`; `.config/iterm2/AppSupport` points at untracked app state. These stay absolute by design and are excluded from `just lint-symlinks`.
- **3 ancestor-discoverable configs.** `.config/mise/config.toml`, `.editorconfig`, and `.envrc` are found by tools that walk up from cwd. Because a dotfiles worktree lives beneath the real `$HOME`, such a tool can discover the real `$HOME`'s copy instead of the worktree's own. `wt --test`/`wt --shell` warn on stderr only when the two copies actually differ.

## Creating, Switching, Deleting

Use the `git-worktree` skill (`/git:worktree`). It owns the executable
procedure and the session rebase; this skill owns the layout and constraints
it enforces.

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
**Pairs with:** branch-finish for cleanup after work is complete, git-worktree for the executable actions
