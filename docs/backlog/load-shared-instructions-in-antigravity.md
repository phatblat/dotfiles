# Load shared instructions in Antigravity

Priority: Unprioritized

## Problem

Rules added to the shared harness instructions (`~/.agents/harness/instructions.md`) do not reach the Antigravity harness. It runs without them, and every future shared rule inherits the same gap. `just harness-audit` lists it as open:

```text
- instructions.global (antigravity): Install or import the Antigravity plugin and verify it loads shared harness instructions
```

For example, `6c3fcc3` added the Explicit configuration rule to `## Operating Discipline`. That rule reaches claude, codex, opencode, and pi through the shared instructions, and reaches omp and codex through the `AGENTS.md` pointer added in `498f653`. It does not reach Antigravity.

## Outcome

Antigravity loads the shared instructions, verified in a live session, and `just harness-audit` no longer lists `instructions.global` for it.

## Notes

- Next action: install or link the generated plugin and verify instruction loading. That is `~/.agents/harness/adapters/antigravity/plugin.json`. Verifying needs the tool installed; `tests/agent-harnesses.bats` skips its `agy plugin validate` test when `agy` is missing.
- [2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](../decisions/2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md) is still proposed. Its clause 1 takes Antigravity out of the user-tier generator entirely. If it is accepted, this item will not be implemented and should be deleted.
- Imported from [#411](https://github.com/phatblat/dotfiles/issues/411).
