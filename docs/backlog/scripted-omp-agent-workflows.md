# Scripted omp agent workflows

Priority: Unprioritized

## Problem

The omp agent team runs its workflows through a lead — the main session — that
dispatches specialists with the `task` tool, so step order and hand-offs
depend on that session's judgment. Workflows whose sequence must be
guaranteed — fixed waves, typed results passed from one step to the next, one
failed branch not sinking the rest — have no deterministic driver. omp's eval
`agent()` / `workpool()` primitives provide one, but nothing in this
repository uses them.

## Outcome

At least one workflow runs as an omp eval script that spawns this repository's
omp agents through `agent()` / `workpool()` in fixed, acyclic waves, passes
schema-validated results between steps, and isolates per-branch failures with
`wait(..., raise_errors=False)`. The workflow has a documented entry point.

## Notes

- Deferred from the agent-team brainstorm on 2026-10-11 as "approach 2"; the
  team in
  [2026-10-11-omp-feature-delivery-team](../decisions/2026-10-11-omp-feature-delivery-team.md)
  goes first and supplies the agent definitions this builds on.
- omp references (18.8.9): `xd://eval/agents` (DAG waves, `AgentHandle`,
  `workpool`), `omp://tools/eval.md`, `eval.workpool.freshAgents`.
- Trade-off accepted when deferring: omp-only (no parity in other harnesses),
  Python/JS authored, and harder to steer mid-run than a lead session.
