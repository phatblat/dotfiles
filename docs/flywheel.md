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
| Mechanism | Native user-level session stores (`scripts/harness_paths.py` `SESSION_STORES`) are scanned aggregate-only by `scripts/harness-sessions.py`. End-of-session hooks append one outcome record (`date`, `harness`, `session_id`, `task`, `outcome`, `corrected`) to `~/.local/state/flywheel/dotfiles/outcomes.jsonl`. Hooks record the observable end state, not a judgment of task success: omp `failed` on a final `stopReason: error`, `abandoned` on `aborted`, else `success`, and `corrected` when the user interrupts a run and then prompts again; claude `success` on `SessionEnd` and `failed` on `StopFailure`; codex `success` on each `Stop`. `flywheel-report.py` keeps the worst outcome per session. Manual step: `just flywheel-record outcome --harness <slug> --outcome <success\|partial\|failed\|abandoned> [--corrected]`. Scaffolds append timestamped firings to `~/.local/state/flywheel/dotfiles/scaffolds.jsonl`. Not wired: opencode, pi, cursor, grok, antigravity, and crush (finding L6). |
| Implementation | `scripts/harness_paths.py`, `scripts/harness-sessions.py`, `scripts/flywheel-record.py`, `just flywheel-record`, `.omp/agent/extensions/flywheel-outcome.ts`, `.claude/hooks/scripts/flywheel-outcome.sh`, `.claude/settings.json`, `.codex/hooks/scripts/audit-task-complete.sh`, `.codex/hooks.json` |
| Cadence | Continuous: one record per session end (claude `SessionEnd`/`StopFailure`, codex `Stop`, omp session switch or shutdown), scanned over a 30-day window. |
| Evidence | `~/.local/state/flywheel/dotfiles/outcomes.jsonl`, `~/.local/state/flywheel/dotfiles/scaffolds.jsonl` |
| Status | implemented |

## 3. Learn

How records become evidence-backed lessons: analysis, retros, or replay on
a better model.

| Field | Value |
|---|---|
| Mechanism | Once per 30-day window, and when `just harness-probe` reports a harness or model upgrade, run `just flywheel-report --since 30`. It joins the outcome and scaffold ledgers with `scripts/harness-sessions.py` aggregates and prints counts only. Feed it through the `optimize-harness` skill and write dated, evidence-cited findings (ID, evidence, proposed change, disposition) to `docs/flywheel/findings/YYYY-MM-DD.md`. Findings stay out of `docs/harness/`, where `harness-generate` deletes unknown `*.md` files as orphans. Replay cases: none yet. |
| Implementation | `scripts/flywheel-report.py`, `just flywheel-report`, `scripts/harness-sessions.py`, `~/.agents/skills/optimize-harness/SKILL.md` |
| Cadence | Every 30 days, and when `just harness-probe` reports a harness or model upgrade. |
| Evidence | `docs/flywheel/findings/2026-10-26.md` |
| Status | implemented |

## 4. Apply

How lessons change instructions, skills, hooks, memory, and model choice,
behind human review.

| Field | Value |
|---|---|
| Mechanism | Every finding gets a disposition in its findings file's Disposition column, and the Cycle log's Changes column cites it by ID: `applied` with the commit, or `declined` with a reason. Applied changes are human-reviewed commits that cite the finding ID, made through the `retro` skill, `scripts/agent-harnesses.py`, `scripts/harness-apply.py`, or OMP `learn`/`manage_skill`, under `.agents/harness/self-improve-policy.json`. Agents never edit control-plane files (`[control_plane]` in `~/.config/ness/policy.toml`); those changes go to `~/.local/state/flywheel/dotfiles/patches/` for a human to apply. |
| Implementation | `docs/flywheel/findings/2026-10-26.md`, `.agents/harness/self-improve-policy.json`, `~/.local/state/flywheel/dotfiles/patches` |
| Cadence | After each Learn run, within the 30-day window. |
| Evidence | `docs/flywheel/findings/2026-10-26.md` |
| Status | implemented |

## 5. Prune

How scaffolding the model no longer needs is removed, on a stopped firing
signal or a passing ablation.

| Field | Value |
|---|---|
| Mechanism | Every 30 days and on model or harness upgrades (`just harness-probe`), compare the Scaffolding register with `just flywheel-report`'s Scaffold firings table and flag rows with no firing in the window. Removal requires a 3-run, fixed-budget ablation that holds success, cost, latency, and safety, and each passing removal goes in its own PR. No replay cases exist yet, so no ablation can run (finding L1's prune waits on one). |
| Implementation | `scripts/flywheel-report.py`, `just flywheel-report`, `docs/flywheel.md` |
| Cadence | Every 30 days and on model or harness version upgrades. |
| Evidence | `docs/flywheel.md`, `docs/flywheel/findings/2026-10-26.md` |
| Status | implemented |

## 6. Tune

How the loop itself is measured and adjusted each cycle.

| Field | Value |
|---|---|
| Mechanism | At the end of each 30-day cycle, and after `just harness-probe` drift checks, run the `flywheel` skill's review mode. Record coverage, cadence, yield, regressions, and cost per task in the Cycle log, writing `unknown` for any metric that can't be measured, plus one decision that keeps or changes the loop. Coverage and friction come from `just flywheel-report`; regressions come from `git log --since=30.days -i --grep=revert` on the paths the loop touched. |
| Implementation | `docs/flywheel.md`, `scripts/flywheel-report.py`, `just harness-probe`, `docs/harness/drift.jsonl` |
| Cadence | Every 30 days at the close of each flywheel cycle. |
| Evidence | `docs/flywheel.md`, `docs/harness/drift.md` |
| Status | implemented |

## Scaffolding register

Instructions, hooks, tools, and nudges that compensate for a model
weakness. Never list runtime, security, permission, secret-handling,
spend-limit, or efficiency controls here.

| Scaffold | Path | Compensates for | Added | Firing signal | Last fired | Remove when |
|---|---|---|---|---|---|---|
| OMP unknown tool hint extension | `.omp/agent/extensions/unknown-tool-hint.ts` | Models guessing underscore-prefixed (`_bash`, `_read`), case-typo'd (`Bash`), or malformed (`xd_recall`, `git_commit`) tool names instead of native tools or `xd://` URIs | 2026-08-25 | `scaffolds.jsonl` `omp-unknown-tool-hint` (logged since 2026-10-26); the misses it targets appear in `just flywheel-report` friction | none observed: 0 of 31 misses intercepted in 30d and 0 `scaffolds.jsonl` firings (finding L1; ablation candidate, gated on 3 replay cases) | No firing across a 30-day window while misses continue (it is inert), or zero misses and a passing 3-run ablation |
| OMP backlog-batch plan review opener | `.omp/agent/extensions/backlog-batch-delivery.ts` | Plan-mode runs of `backlog-batch-delivery` writing `local://*plan.md` and ending turn without calling `xd://propose` | 2026-10-16 | `scaffolds.jsonl` `omp-backlog-batch-plan-review` (logged since 2026-10-26) | unknown: the skill was invoked 14 times in 30d, but fallback openings were not logged before 2026-10-26 | Fallback stays at 0 firings across a 30-day window and passes a 3-run ablation |
| Claude PostToolUse auto-format hook | `.claude/hooks/scripts/auto-format.sh` | Models editing files without running `hk fix` / `prettier` / `ruff` | 2026-06-14 | `scaffolds.jsonl` `claude-auto-format`, written when formatting changes the file's bytes (logged since 2026-10-26) | unknown: byte changes were not logged before 2026-10-26; last Claude session 2026-10-12 | Zero post-edit format diffs across a 30-day window and passing 3-run ablation |
| Codex PostToolUse auto-format hook | `.codex/hooks/scripts/auto-format.sh` | Models editing files in Codex without running `hk fix` / `prettier` / `ruff` | 2026-08-20 | `scaffolds.jsonl` `codex-auto-format`, written when formatting changes a file's bytes (logged since 2026-10-26) | unknown: not logged before 2026-10-26; 1 Codex session in 30d | Zero post-edit format diffs across a 30-day window and passing 3-run ablation |
| Claude PreToolUse pre-commit format hook | `.claude/hooks/scripts/pre-commit-format.sh` | Models running `git commit` with unformatted tracked files | 2026-07-19 | `scaffolds.jsonl` `claude-pre-commit-format` (`staged=1`, logged since 2026-10-26) | unknown: not logged before 2026-10-26 | `staged=1` never fires across a 30-day window and passing 3-run ablation |
| Claude PreCompact preservation reminder | `.claude/hooks/scripts/pre-compact.sh` | Compaction dropping uncommitted file counts, active branch, and pending tasks | 2026-06-14 | `scaffolds.jsonl` `claude-pre-compact` (logged since 2026-10-26) | unknown: Claude transcripts hold 0 `PreCompact` hook runs against 13 compaction records in 30d, so the hook's runs were never recorded | Native compaction preserves branch and dirty-file state without hook in 3-run ablation |
| OMP `cd <path> &&` prohibition | `.omp/agent/AGENTS.md` | Models prefixing `bash` tool commands with redundant `cd <path> &&` instead of passing `cwd` | 2026-09-28 | `scripts/harness-sessions.py` `scaffold_signal` `omp-cd-prefix` (`just flywheel-report`) | 2026-10-26: 3015 in 30d; weekly share of `bash` calls fell from 43-66% to 13-25% after the rule (finding L2) | Zero leading `cd <path> &&` calls across a 30-day window and passing 3-run ablation |
| Tessl pointer re-injection cleanup rule | `AGENTS.md` | `tessl init` re-injecting `@../.tessl/RULES.md` into harness instruction files | 2026-09-21 | `bats tests/tessl-inclusion.bats` failure | none observed: `bats tests/tessl-inclusion.bats` passed (3/3) on 2026-10-26 (ablation candidate, gated on 3 replay cases or `tessl` retirement) | `tessl init` stops injecting duplicate pointers or `tessl` is retired |

## Cycle log

| Date | Stages run | Findings | Changes | Metrics | Next |
|---|---|---|---|---|---|
| 2026-10-26 | setup | 14 existing pieces found | created docs/flywheel.md | coverage: 0/9 outcome ledger (8/9 session stores scanned, 7/9 active in 30d); cadence: Enable 0d, Record/Learn/Apply/Prune/Tune never; yield: unknown; regressions: 0; cost_per_task: unknown | 2. Record |
| 2026-10-26 | review: Enable, Record, Learn, Apply, Prune, Tune | review: 4 High, 3 Medium, 2 Low; Learn: L1-L6 (`docs/flywheel/findings/2026-10-26.md`) | F1/F5: opencode `debug config --pure` probe fixed in 0b3ac2b; the matching control-plane `scripts/agent-harnesses.py` fix landed in 7249684, and `just harness-check` passes. F2/F8: omp, claude, and codex outcome hooks and firing logs for every register row (81b10a6). F3: `just flywheel-report` (22e8685) and the first findings file. F4: L1 applied in 81b10a6, L3 in 5193e66; L2, L4, L5, and L6 declined with reasons in the findings file. F6/F9: register signals and last-fired evidence refreshed; the unknown-tool hint flagged as inert, and no ablation run because no replay cases exist. F7: Tune wired. | coverage: 3/9 harnesses with outcome hooks, 0/9 with outcome records yet (hooks wired 2026-10-26); cadence: all six stages 0d against a 30d cadence; yield: 2/6 findings applied; regressions: 0 reverts of flywheel changes (no earlier applied changes); cost_per_task: unknown | Keep the 30d cadence. Next cycle: build 3 replay cases so Prune can ablate the unknown-tool hint. |
| 2026-10-26 | review | 0 High, 0 Medium, 2 Low | F1, F2: refreshed `OMP unknown tool hint extension` and `Tessl pointer re-injection cleanup rule` ablation status and rolling 30d counts (`omp-cd-prefix` 3015); neither scaffold removed without a 3-run ablation | coverage: 1/9 harnesses with session files and outcome records in 30d (omp: 3 sessions, 2 success, 1 abandoned, 0/3 corrected; 3/9 wired with outcome hooks); cadence: all six stages 0d against a 30d cadence; yield: 2/6 findings applied (`docs/flywheel/findings/2026-10-26.md`); regressions: 0 reverts on flywheel-touched paths in 30d; cost_per_task: unknown | Build 3 fixed-budget replay cases so Prune can run 3-run ablations on the unknown-tool hint and Tessl cleanup rule. |
