# Repository Guidelines

## Project Structure & Module Organization
This repository is rooted at `~/` and tracks personal dotfiles plus automation.

- `.config/`: primary configuration modules (shells, `mise`, `home-manager`, editors).
- `.claude/`: agent, command, and workflow configuration.
- `bin/`: executable utility scripts.
- `scripts/`: supporting scripts (for example, `sort-gitignore`, `sort-tools.py`).
- `tests/`: Bats smoke tests and shared helpers.
- `.harness/`: CI pipeline definitions.
- `docs/`: project documentation.

Most contribution work happens in hidden config directories and shell function files under `.config/*`.

## Build, Test, and Development Commands
Use `just` recipes from the repo root:

- `just --list`: show all available workflows.
- `just install`: install pinned tooling via `mise`.
- `just format`: format `justfile`, `mise` config, JSON settings, and shell scripts.
- `just lint`: run full lint/format checks (includes `just --fmt --check`, `mise fmt --check`, shell checks).
- `just test`: run Bats tests in `~/tests`.
- `just doctor`: run local environment diagnostics (`mise`, Homebrew, Claude tooling).

## Coding Style & Naming Conventions
- Follow `.editorconfig`: UTF-8, LF, final newline, 2-space indent by default.
- Use 4 spaces for `*.{gradle,java,kt,kts}`; tabs for `Makefile`, `*.plist`, `*.gitconfig`.
- Keep shell scripts lint-clean with `shellcheck`; format shell code with `shfmt`.
- For tests, use descriptive Bats names: `@test "tool is available" { ... }`.
- Keep scripts and function names concise, lowercase, and task-oriented (`sort-gitignore`, `lint-zsh`).

## Testing Guidelines
- Framework: `bats-core`.
- Location: `tests/*.bats`, helpers in `tests/helpers/`.
- Run locally with `just test` before opening a PR.
- Validate lint + tests together with `just lint && just test`.
- CI (`.harness/ci.yaml`) runs lint, tests, then a Nix build stage.

## Commit & Pull Request Guidelines
- Use Conventional Commit prefixes seen in history (`feat:`, `fix:`, `chore:`, `deps:`, `style:`, `test:`, `ci:`), optionally scoped (`feat(justfile): ...`).
- Follow `.gitmessage`: imperative subject, capitalized, no trailing period, <= 50 chars; wrap body at 72 chars and explain what/why.
- PRs should include: concise summary, changed paths, commands run locally, and any relevant config/output screenshots.
