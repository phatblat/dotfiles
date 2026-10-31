# Load shared instructions in Antigravity and Cursor

Priority: Unprioritized

## Problem

Rules added to the shared harness instructions (`~/.agents/harness/instructions.md`) do not reach the Antigravity or Cursor harnesses. Both run without them, and every future shared rule inherits the same gap. `just harness-audit` lists both as open:

```text
- instructions.global (antigravity): Install or import the Antigravity plugin and verify it loads shared harness instructions
- instructions.global (cursor): Link or install the Cursor plugin and verify Cursor loads the shared-harness rule
```

For example, `6c3fcc3` added the Explicit configuration rule to `## Operating Discipline`. That rule reaches claude, codex, opencode, and pi through the shared instructions, and reaches omp and codex through the `AGENTS.md` pointer added in `498f653`. It does not reach Antigravity or Cursor.

## Outcome

Antigravity and Cursor load the shared instructions, verified in a live session of each, and `just harness-audit` no longer lists `instructions.global` for either.

## Notes

- Next action: install or link the generated plugins and verify instruction loading. For Antigravity that is `~/.agents/harness/adapters/antigravity/plugin.json`. For Cursor it is `~/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json` with `rules/shared-harness.mdc`. Verifying needs both tools installed; `tests/agent-harnesses.bats` skips its `agy plugin validate` test when `agy` is missing.
- [2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](../decisions/2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md) is still proposed. Its clause 1 takes Cursor and Antigravity out of the user-tier generator entirely. If it is accepted, this item will not be implemented and should be deleted.
- Imported from [#411](https://github.com/phatblat/dotfiles/issues/411).
