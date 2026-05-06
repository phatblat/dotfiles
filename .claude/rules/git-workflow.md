---
paths:
  - ".gitconfig"
  - ".config/git/**"
  - ".gitignore"
---

# Git Workflow Conventions

## Commits

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:` (imperative mood, present tense)
- GPG signing enabled globally
- Never bypass hooks with `--no-verify`

## Branches

- Feature branches: `ben/<topic>` or daily weekday names
- Every new branch MUST have remote tracking set up immediately after creation:
  ```bash
  git push -u <remote> <branch>:<branch>
  ```
- Verify with `git branch -vv`. Never let tracking point to the source branch.
- `main` is protected — cannot push directly

## Worktrees

- Location: `~/.worktrees/<path-key>/<branch>` ONLY
- `<path-key>` = repo root relative to `~` with `/` replaced by `-`
- **Dotfiles exception:** The dotfiles repo (rooted at `~`) must NOT use worktrees
- After merging/closing a PR: `git worktree remove <worktree-path>`
- Never force push to main/master

## PRs

- PR body: ticket references (e.g., `Resolves DEVX-123`) above the first heading

## Git Config Structure

- Global: `~/.gitconfig` (tracked)
- Local overrides: `~/.config/git/config` (not tracked, machine-specific email)
- Rerere enabled
