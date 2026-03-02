# Mise Bump Polecat Workflow

This runbook captures the repeatable Gas Town workflow for opening one
independent PR per pending `mise` upgrade in dotfiles.

## What This Does

- Reads `mise outdated --bump`
- Creates one bead per pending tool bump
- Slings each bead to the target rig as independent polecat work
- Uses a dedicated formula for one-line `config.toml` bumps
- Uses `--merge=local` so each polecat opens a PR instead of auto-merging

## Prerequisites

- Dotfiles repo is at `/Users/phatblat`
- Gas Town workspace is at `/Users/phatblat/gt`
- Target rig exists (default in recipes: `dotfiles`)
- `gt`, `bd`, `mise`, and `gh` are installed and authenticated
- Formula file exists at:
  - `~/.beads/formulas/dotfiles-mise-bump-pr.formula.toml`

## Commands

Preview dispatches without creating beads/polecats:

```bash
just gt-mise-bump-polecats-dry-run
```

Dispatch all current pending bumps:

```bash
just gt-mise-bump-polecats
```

Dispatch one specific bump manually:

```bash
just gt-mise-bump-polecat gh 2.86.0 2.87.3
```

Override rig name:

```bash
just gt-mise-bump-polecats rig=my-rig
```

## Expected Polecat Output Per Tool

- One-line version bump in `.config/mise/config.toml`
- Commit message:
  - `chore(mise): bump <tool> to <version>`
- Branch name:
  - `ben/mise-bump-<tool>-<version>`
- PR target:
  - `main`
- PR body:
  - `One-line bump in .config/mise/config.toml.`

## Notes

- The script is `~/scripts/gt-mise-bump-polecats`.
- Formula defaults to `dotfiles-mise-bump-pr` and can be overridden with
  `GT_MISE_FORMULA`.
- Workspace defaults to `~/gt` and can be overridden with `GT_WORKSPACE`.
