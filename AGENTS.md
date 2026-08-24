# Repository Guidelines

## Shared Harness Instructions

Read `~/.agents/harness/instructions.md` (symlinked as `~/.agents/AGENTS.md`)
alongside this file. It carries the operating discipline, token, and safety
rules intended for every agent harness, though some adapters do not load it
yet -- `just harness-audit` tracks which. It is generated from
`scripts/agent-harnesses.py`; edit the generator, never the output.

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

## Agent Response Language

- Respond in the language used by the user's latest message.
- If the user's language is unclear, use English.
- Keep code, code comments, and command output unchanged unless translation is explicitly requested.

**Nested repositories:** Some subdirectories (especially `dev/`) are separate git repos. The working directory is already `~`; run git directly or use `git -C ~` (avoid a redundant `cd ~`), and confirm which repo you are in before committing.

## Build, Test, and Development Commands
Use `just` recipes from the repo root:

- `just --list`: show all available workflows.
- `just deps` (alias `i`): install pinned tooling via `mise`.
- `just format`: format `justfile`, `mise` config, JSON settings, and shell scripts.
- `just lint`: run full lint/format checks (includes `just --fmt --check`, `mise fmt --check`, shell checks).
- `bats tests/<name>.bats`: run only the Bats file relevant to the changed behavior.
- `just test`: run the whole Bats suite in parallel (~35s; needs `rush`, installed by `just deps`).
- `just test abort`: run the suite serially and stop at the first failure.
- `just doctor`: run local environment diagnostics (`mise`, Homebrew, Claude tooling).

## Coding Style & Naming Conventions
- Follow `.editorconfig`: UTF-8, LF, final newline, 2-space indent by default.
- Use 4 spaces for `*.{gradle,java,kt,kts}`; tabs for `Makefile`, `*.plist`, `*.gitconfig`.
- Keep shell scripts lint-clean with `shellcheck`; format shell code with `shfmt`.
- For tests, use descriptive Bats names: `@test "tool is available" { ... }`.
- Keep scripts and function names concise, lowercase, and task-oriented (`sort-gitignore`, `lint-zsh`).

### Formatting Policy

- Every file tracked in this repo follows its language's standard formatter
  (`just format`, `.editorconfig`). Formatting is the default, not a per-file
  judgment call.
- The only exception is a tool that breaks when its tracked config or source is
  formatted normally. Document each exception where it applies, as
  `.gitattributes` and `scripts/sort-codex-config.py` already do for Codex's
  marketplace key order and machine-managed state.
- Rationale: uniform formatting keeps `just lint` fast and makes a diff
  meaningful. A tracked file that lands unformatted -- or wholesale reformatted
  -- is evidence the change was not reviewed.
- Let the formatter own whitespace; never hand-churn it. Do not reformat lines a
  change does not touch. Agent writes (pi, OMP) that leave existing whitespace
  as found are fine -- behavior-neutral, and better than a drive-by reformat
  that buries the real diff.

## Testing Guidelines
- Framework: `bats-core`.
- Location: `tests/*.bats`, helpers in `tests/helpers/`.
- Run `just lint` and only the Bats files relevant to the changed behavior.
- Run a repository-wide test suite only when the user explicitly requests it.
- CI: GitHub Actions runs on every push — `lint.yml` (lint job, plus a test job that runs `just test`) and `agent-harness-parity.yml`.
- `.harness/` describes an older pipeline (lint, tests, Nix build) but is inert: it triggers on GitHub webhooks and the repo has none configured, so it cannot run. Do not treat it as a gate or spend time maintaining it.

## Web & Documentation Search (Exa)

Use `~/.claude/skills/exa-search/scripts/exa.sh` to verify API signatures, look
up library usage, or check a config format — including when you think you
already know the answer, since library APIs drift. `EXA_API_KEY` is read from
`~/.env`; never pass the key on a command line.

```bash
exa.sh context "expose a Rust struct to Node via napi-rs threadsafe function"
exa.sh search  "napi-rs breaking changes" --domains github.com --since 2026-01-25
```

`context` is the default — it returns one budget-capped string and is the
token-efficient path for anything code-shaped. Fall through to `search` only for
recency (`context` has no date filter), provenance control (`--domains` /
`--exclude`), or when `context` comes back empty. Narrate that fallback, and do
it at most once; if `search` is also thin, say so and stop rather than
escalating to `--type deep-reasoning`.

Defaults (`--type auto`, `--results 10`, highlights capped at 600 chars) are
right for nearly every coding question. Full parameter tables and API footguns
are in `~/.claude/skills/exa-search/references/search-tuning.md`.

## Commit & Pull Request Guidelines
- Use Conventional Commit prefixes seen in history (`feat:`, `fix:`, `chore:`, `deps:`, `style:`, `test:`, `ci:`), optionally scoped (`feat(justfile): ...`).
- Follow `.gitmessage`: imperative subject, capitalized, no trailing period, <= 50 chars; wrap body at 72 chars and explain what/why.
- PRs should include: concise summary, changed paths, commands run locally, and any relevant config/output screenshots.
