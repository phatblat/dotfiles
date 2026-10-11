# Fix the omp agent discovery check

## Problem

`scripts/agent-harnesses.py verify` checks omp agent discovery by running
`omp task-agent list` (`command_verify`, around line 656). omp 18.8.9 has no
`task-agent` subcommand: `omp task-agent --help` prints the usage for
`omp launch`, so the words are parsed as a prompt, not as a listing request.
The check therefore cannot count discovered agents. Depending on how that
launch behaves without a TTY, it either reports a misleading agent count or
exceeds its 5-second `timeout`, which `subprocess.run` raises as an uncaught
`TimeoutExpired` (not reproduced; running it would send a prompt to a model).
The only agent-related CLI in 18.8.9 is `omp agents`, whose sole action is
`unpack` for bundled agents.

## Outcome

`verify` for omp reports how many of the generated specialist agents omp
actually discovers, using a mechanism that exists in the installed omp, never
sends a model prompt, and cannot crash `verify` on timeout.

## Notes

- Candidate mechanisms: omp's RPC mode, or a print-mode `task` preflight whose
  `Unknown agent "…". Available: …` error lists discovered agents
  (`omp://task-agent-discovery.md`, "Agent lookup and selection"). Both need a
  check that they start no model turn.
- Found while designing
  [2026-10-11-omp-feature-delivery-team](../decisions/2026-10-11-omp-feature-delivery-team.md).
