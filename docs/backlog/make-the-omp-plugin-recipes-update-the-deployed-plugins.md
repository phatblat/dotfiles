# Make the omp plugin recipes update the deployed plugins

Priority: Medium

## Problem

`just omp-plugins-update`, `just omp-plugins-reinstall`, and `just install-bun-deps` run `bun` inside the checkout's `.omp/plugins` (`.config/just/omp.just`), but OMP loads plugins from `~/.omp/plugins/node_modules`, a real directory in which only `package.json` and `omp-plugins.lock.json` are symlinks into the checkout. Running `just omp-plugins-update` during the 2026-11-26 audit moved the checkout's `node_modules` to `pi-continual-harness` 0.20.0 while `~/.omp/plugins/node_modules` stayed at 0.18.0 and the tracked `omp-plugins.lock.json` still records 0.18.0 against a manifest range of `^0.20.0`. The recipes therefore cannot reconcile the manifest and the lock, and a manifest bump never reaches the running harness.

## Outcome

After `just omp-plugins-update`, the version in `~/.omp/plugins/node_modules/pi-continual-harness/package.json` satisfies the range in `.omp/plugins/package.json`, and `omp-plugins.lock.json` records that version.

## Notes

- The layout predates the move of the checkout from `~` to `~/dev/dotfiles`: when `~` was the repo root, the checkout's `.omp/plugins` and `~/.omp/plugins` were the same directory.
- `.omp/plugins/bun.lock` and `node_modules` are ignored (`.gitignore`, `.omp/plugins/*`), so the checkout copy is invisible to `git status`.
- Finding L10 of `docs/flywheel/findings/2026-11-26.md`.
