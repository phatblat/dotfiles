---
name: git-worktree
description: Create, switch to, or delete a git worktree under ~/.worktrees/<path-key>/<branch>, then rebase the agent session onto that directory. Use when asked to make, enter, or remove a worktree for a branch, when work needs an isolated checkout, or when invoked as /git:worktree.
---

# Git Worktree

**Announce at start:** "Using git-worktree skill to <action> the worktree for <branch>."

## Contract

This skill never re-derives worktree paths in prose. `~/.agents/skills/git-worktree/wt.sh` is the single agent-side implementation; invoke it with that exact tilde path so the command's `allowed-tools` prefix matches. Layout and constraint questions belong to the `using-git-worktrees` skill.

## Actions

| Invocation | Effect |
| --- | --- |
| `wt.sh path <branch> [--dotfiles]` | prints the path that *would* be used; mutates nothing |
| `wt.sh resolve <branch> [--dotfiles]` | prints the registered worktree path, or exits 3 |
| `wt.sh switch <branch> [--dotfiles]` | resolve, else create; prints the path (this is `wt <branch>`) |
| `wt.sh create <branch> [--dotfiles]` | create only; exits 4 if already registered |
| `wt.sh remove <branch> [--dotfiles] [--force]` | `git worktree remove` + prune; never touches the branch |
| `wt.sh list` | one `<path>\t<branch>` line per worktree (agents cannot use `wt`'s fzf picker) |
| `wt.sh verify <branch>` | dotfiles only: `just check` with `HOME` remapped, mirroring `wt --test` |

## Session Rebase Protocol

The load-bearing part. Three parts, in this order:

### A. Bind the worktree (always, immediately, no waiting)

Capture the path:

```bash
wt_path=$(~/.agents/skills/git-worktree/wt.sh switch "$branch" ${dotfiles:+--dotfiles})
```

From this point in the session:

- every shell call passes the worktree as the working directory — `git -C "$wt_path" …`, or the Bash tool's `cwd` parameter (omp resolves an absolute `cwd` outside the session directory fine; verified)
- every file tool call (`read`/`grep`/`glob`/`edit`) uses absolute paths under `$wt_path`
- **every `task` subagent prompt states `$wt_path` and requires absolute paths under it.** Subagents inherit the parent's cwd and the `task` tool has no `cwd` field, so a subagent given relative paths silently works in the wrong tree
- the final report restates `$wt_path` verbatim, so the binding survives context compaction

### B. Move the harness's own root (one line, user-run)

Detect the harness — **order matters, omp sets both `OMPCODE=1` and `CLAUDECODE=1`**:

```bash
if [ -n "${OMPCODE:-}" ]; then harness=omp
elif [ -n "${CLAUDECODE:-}" ]; then harness=claude
else harness=other; fi
```

Then print exactly one line for the user to run:

| Harness | Line to print | Truth to state alongside it |
| --- | --- | --- |
| `omp` | `/move <wt_path>` | a real cwd change that keeps this conversation, and reloads project-scoped settings/plugins/commands for the worktree. The agent cannot self-invoke slash commands, so the user runs it. Offer `/add-dir <wt_path>` instead when they want both roots live, and `/dirs` to inspect. |
| `claude` | `/add-dir <wt_path>` | Claude Code has **no** cwd-change command; this only grants access, so `pwd` stays put and part A remains the working mechanism |
| `other` | `omp --cwd <wt_path>` | starts a fresh session rooted at the worktree; loses this conversation. `--cwd` also bypasses omp's `~`→temp-dir auto-switch |

Never suggest `omp worktree`/`omp wt` here: that CLI manages omp's own agent worktrees under `~/.omp/wt` and has nothing to do with `~/.worktrees/`.

### C. Never block on B

Continue the task under part A whether or not the user runs the line. Do not use `AskUserQuestion` to wait for it.

## Deleting

`wt.sh remove` refuses in three cases; the skill explains each rather than reaching for `--force`:

- the current session directory (or `$PWD`) is inside the target worktree → tell the user to `/move` out (omp) or work from another root first
- the target is the repo's main worktree → never removable
- the worktree has uncommitted changes → report `git -C <path> status --porcelain=v1` and ask before re-running with `--force`

Branch deletion is out of scope and stays with `git-cleanup` / `branch-finish`. After a successful remove, print `git -C <repo_root> branch -d <branch>` as the follow-up the user may want, and do not run it.

## Never

- Never re-derive the worktree path in prose or with an ad-hoc `sed`/`tr` pipeline — call `wt.sh path`.
- Never create a dotfiles worktree without `--dotfiles`.
- Never use a dotfiles worktree to validate `.zshrc`, `.zshenv`, `.zprofile`, or `.config/zsh/functions/**` (see `using-git-worktrees`).
- Never `git worktree add` a path whose leaf differs from the branch name.
- Never remove a worktree to "fix" a dirty tree.
- Never invoke `omp worktree` / `omp wt`, and never describe them as related: they manage omp's own agent worktrees under `~/.omp/wt`, not `~/.worktrees/`.
- Never hand a subagent a relative path and assume it lands in the worktree — subagents inherit the parent cwd.

## Integration

**Pairs with:** using-git-worktrees (layout/constraints), branch-finish (post-merge cleanup), git-stack (already creates worktrees under the same convention).
