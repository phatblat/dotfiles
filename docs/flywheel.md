# Agent Flywheel

<!-- Maintained with the flywheel skill. Keep the five-field table in every
stage section so a review can check it. Status is planned or implemented. -->

The learning loop for agents working in this repo. Each turn runs Enable →
Record → Learn → Apply → Prune → Tune, then starts again.

- Harnesses in use: claude, codex, cursor, antigravity, opencode, pi, omp, grok, crush
- Evidence window: 30 days
- Last reviewed: 2026-10-26

## 1. Enable

What the harness gives agents so they can attempt harder tasks.

| Field | Value |
|---|---|
| Mechanism | Shared harness generator (`scripts/agent-harnesses.py`) emits instructions, skills, commands, agents, MCP configs, and normalized `ness` safety guard shims across all 9 harnesses, paired with repo-level instructions (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`) and per-harness hooks/extensions. |
| Implementation | `AGENTS.md`, `.agents/harness/instructions.md`, `CLAUDE.md`, `GEMINI.md`, `.codex/AGENTS.md`, `.omp/agent/AGENTS.md`, `.config/crush/shared-harness.md`, `.agents/skills`, `.claude/skills`, `.mcp.json`, `.claude/mcp.json`, `.cursor/mcp.json`, `.agents/harness/hooks/contract.json`, `~/.config/ness/policy.toml`, `.claude/settings.json`, `.claude/hooks/scripts/write-guard.sh`, `.claude/hooks/scripts/bash-guard.sh`, `.claude/hooks/scripts/user-prompt-secrets.sh`, `.claude/hooks/scripts/auto-format.sh`, `.claude/hooks/scripts/pre-commit-format.sh`, `.claude/hooks/scripts/pre-compact.sh`, `.claude/hooks/scripts/posttooluse-failure.sh`, `.codex/hooks.json`, `.codex/hooks/scripts/write-guard.sh`, `.codex/hooks/scripts/bash-guard.sh`, `.codex/hooks/scripts/user-prompt-secrets.sh`, `.codex/hooks/scripts/auto-format.sh`, `.codex/hooks/scripts/audit-task-complete.sh`, `.cursor/hooks.json`, `.grok/hooks/harness-guard.json`, `.omp/agent/hooks/pre/harness-guard.ts`, `.omp/agent/extensions/unknown-tool-hint.ts`, `.omp/agent/extensions/backlog-batch-delivery.ts`, `.pi/agent/extensions/harness.ts`, `.config/opencode/plugins/harness.ts`, `.config/crush/crushrc`, `scripts/agent-harnesses.py`, `just harness-check`, `just harness-audit` |
| Cadence | On every pre-commit (`hk` `generate` step) and CI push (`agent-harness-parity.yml`), plus on harness release via `just harness-probe`. |
| Evidence | `docs/agent-harnesses.md`, `docs/agent-harnesses.json`, `docs/harness/instructions.md`, `docs/harness/hooks.md`, `docs/harness/skills.md`, `docs/harness/mcp.md` |
| Status | implemented |

## 2. Record

How experience outlives the session: sessions, outcomes, friction, and
scaffold firings. Raw transcripts stay out of git.

| Field | Value |
|---|---|
| Mechanism | Retain native user-level session stores mapped in `scripts/harness_paths.py` (`SESSION_STORES`), scan aggregate usage and friction with `scripts/harness-sessions.py` (`just harness-sessions`), append per-task outcome records (`date`, `harness`, `session_id`, `task`, `outcome`, `corrected`) to `~/.local/state/flywheel/dotfiles/outcomes.jsonl` via end-of-session hooks (`SessionEnd` / `Stop` / `agent_end`) or manual step, and log timestamped scaffold firings. |
| Implementation | none |
| Cadence | Continuous per session (`SessionEnd` / `Stop` / `agent_end`), scanned over a 30-day window. |
| Evidence | none |
| Status | planned |

## 3. Learn

How records become evidence-backed lessons: analysis, retros, or replay on
a better model.

| Field | Value |
|---|---|
| Mechanism | Run `python3 ~/scripts/harness-sessions.py claude codex cursor antigravity opencode pi omp grok crush --since 30 --json` and the outcome ledger through the `optimize-harness` skill once per 30-day window (plus 3-run fixed-budget Harbor replay cases via `just harness-evals` on model/harness upgrades) to write dated, evidence-cited findings to `docs/harness/findings/YYYY-MM-DD.md`. |
| Implementation | none |
| Cadence | Every 30 days, and when `just harness-probe` reports a harness or model upgrade. |
| Evidence | none |
| Status | planned |

## 4. Apply

How lessons change instructions, skills, hooks, memory, and model choice,
behind human review.

| Field | Value |
|---|---|
| Mechanism | Convert each finding in `docs/harness/findings/YYYY-MM-DD.md` into a human-reviewed commit/PR (via the `retro` skill, `scripts/agent-harnesses.py`, `scripts/harness-apply.py`, or OMP `learn`/`manage_skill`) under `.agents/harness/self-improve-policy.json` guardrails, citing the finding ID and recording `applied` (with commit SHA) or `declined` (with reason) in the Cycle log. |
| Implementation | none |
| Cadence | After each Learn run, within the 30-day window. |
| Evidence | none |
| Status | planned |

## 5. Prune

How scaffolding the model no longer needs is removed, on a stopped firing
signal or a passing ablation.

| Field | Value |
|---|---|
| Mechanism | Audit the Scaffolding register every 30 days and on model/harness upgrades (`just harness-probe`), flag rows with 0 firings in the 30-day window, run a 3-trial fixed-budget ablation holding success, cost, latency, and safety constant, and propose each passing removal as its own PR. |
| Implementation | none |
| Cadence | Every 30 days and on model or harness version upgrades. |
| Evidence | none |
| Status | planned |

## 6. Tune

How the loop itself is measured and adjusted each cycle.

| Field | Value |
|---|---|
| Mechanism | At the end of each 30-day cycle (and after `just harness-probe` drift checks), run `flywheel review`, record coverage, cadence, yield, regressions, and cost per task in the Cycle log, and record one decision adjusting or keeping the loop. |
| Implementation | none |
| Cadence | Every 30 days at the close of each flywheel cycle. |
| Evidence | none |
| Status | planned |

## Scaffolding register

Instructions, hooks, tools, and nudges that compensate for a model
weakness. Never list runtime, security, permission, secret-handling,
spend-limit, or efficiency controls here.

| Scaffold | Path | Compensates for | Added | Firing signal | Last fired | Remove when |
|---|---|---|---|---|---|---|
| OMP unknown tool hint extension | `.omp/agent/extensions/unknown-tool-hint.ts` | Models guessing underscore-prefixed (`_bash`, `_read`), case-typo'd (`Bash`), or malformed (`xd_recall`, `git_commit`) tool names instead of native tools or `xd://` URIs | 2026-08-25 | `scripts/harness-sessions.py` `friction.error_classes` (`class: "not_found"` on `_bash`, `_read`, `_write`, `xd_recall`, `xd___recall`, `run`, `skill`, `artifact`, `PATH`, `xd`) | 2026-10-25 | Zero unknown-tool `not_found` misses across a 30-day window and passing 3-run ablation |
| OMP backlog-batch plan review opener | `.omp/agent/extensions/backlog-batch-delivery.ts` | Plan-mode runs of `backlog-batch-delivery` writing `local://*plan.md` and ending turn without calling `xd://propose` | 2026-10-16 | None yet (add timestamped counter when `ctx.openPlanReview()` fallback fires on `agent_end`) | unknown | Fallback counter stays 0 across a 30-day window and passing 3-run ablation |
| Claude PostToolUse auto-format hook | `.claude/hooks/scripts/auto-format.sh` | Models editing files without running `hk fix` / `prettier` / `ruff` | 2026-06-14 | `scripts/harness-sessions.py` Claude `hook_run` records for `auto-format.sh` (add modified-file log line when formatting changes bytes) | 2026-10-12 | Zero post-edit format diffs across a 30-day window and passing 3-run ablation |
| Codex PostToolUse auto-format hook | `.codex/hooks/scripts/auto-format.sh` | Models editing files in Codex without running `hk fix` / `prettier` / `ruff` | 2026-08-20 | None yet (add timestamped log line when `hk fix` changes file hash) | unknown | Zero post-edit format diffs across a 30-day window and passing 3-run ablation |
| Claude PreToolUse pre-commit format hook | `.claude/hooks/scripts/pre-commit-format.sh` | Models running `git commit` with unformatted tracked files | 2026-07-19 | `systemMessage: "Auto-formatted and staged changed files before commit."` (`staged=1`) in Claude transcripts | unknown | `staged=1` never fires across a 30-day window and passing 3-run ablation |
| Claude PreCompact preservation reminder | `.claude/hooks/scripts/pre-compact.sh` | Compaction dropping uncommitted file counts, active branch, and pending tasks | 2026-06-14 | `systemMessage: "📝 Compacting - Preserving: ..."` on Claude `PreCompact` hook runs | unknown | Native compaction preserves branch and dirty-file state without hook in 3-run ablation |
| OMP `cd <path> &&` prohibition | `.omp/agent/AGENTS.md` | Models prefixing `bash` tool commands with redundant `cd <path> &&` instead of passing `cwd` | 2026-09-28 | None yet (add `scripts/harness-sessions.py` check or hook counter for leading `cd ... &&` in OMP `bash` calls) | unknown | Zero leading `cd <path> &&` calls across a 30-day window and passing 3-run ablation |
| Tessl pointer re-injection cleanup rule | `AGENTS.md` | `tessl init` re-injecting `@../.tessl/RULES.md` into harness instruction files | 2026-09-21 | `bats tests/tessl-inclusion.bats` failure | unknown | `tessl init` stops injecting duplicate pointers or `tessl` is retired |

## Cycle log

| Date | Stages run | Findings | Changes | Metrics | Next |
|---|---|---|---|---|---|
| 2026-10-26 | setup | 14 existing pieces found | created docs/flywheel.md | coverage: 0/9 outcome ledger (8/9 session stores scanned, 7/9 active in 30d); cadence: Enable 0d, Record/Learn/Apply/Prune/Tune never; yield: unknown; regressions: 0; cost_per_task: unknown | 2. Record |
