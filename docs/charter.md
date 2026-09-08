# Charter

## Why this exists

`$HOME` is the git root for personal dotfiles: shell setup and system/app
configuration synced across several macOS machines
([`README.md`](../README.md)). This Charter exists because the repository's
documentation had no fixed home and no rule for what graduates into `docs/`
versus what stays scratch — see
[`docs/decisions/2026-09-07-adopt-conventional-docs.md`](decisions/2026-09-07-adopt-conventional-docs.md).

## Goals

- The three parity dimensions in
  [`docs/tooling-dimensions.md`](tooling-dimensions.md) — shells, package
  managers, and agent harnesses — do not silently drift across machines.
- Generated agent-harness artifacts stay reproducible from
  `scripts/agent-harnesses.py generate`; nothing under `.agents/harness/` or
  `docs/harness/` is hand-edited.
- Every tracked file passes its formatter — see `AGENTS.md`'s Formatting
  Policy.

## Artifacts

| Artifact  | Location          | Notes                                                     |
| --------- | ------------------ | ---------------------------------------------------------- |
| Charter   | `docs/charter.md` | this file                                                  |
| Design    | —                  | per-domain docs under `docs/`; no single `docs/design.md`  |
| Decisions | `docs/decisions/`  | in use                                                     |
| Roadmap   | —                  | not used yet — no ordered backlog distinct from ad-hoc work |
| Plan      | —                  | written per branch as `PLAN.md`, deleted at `plan: done`   |
| Todo      | —                  | written per branch as `TODO.md`, deleted at `todo: clear`  |
| Events    | —                  | vocabulary recorded in `AGENTS.md`; no `EVENTS.md`         |
| Runbooks  | —                  | not used                                                   |
| Incidents | —                  | not used                                                   |
| Changelog | —                  | none; the repo cuts no releases                            |

## Route

- [`README.md`](../README.md) — what the repo is and how to use it.
- [`AGENTS.md`](../AGENTS.md) — agent-facing operating rules, including the
  Documentation Convention section.
- [`docs/agent-harnesses.md`](agent-harnesses.md) — generated harness parity
  report.
- [`docs/decisions/`](decisions/) — the decision log.
