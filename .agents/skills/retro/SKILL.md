---
name: retro
description: Improve agent harness configuration based on recent friction points. Use when invoked as `$retro` or when the user asks for autonomous cleanup of Codex, agent harness, or migrated Claude configuration.
---

# retro

Apply targeted agent-configuration improvements based on recent friction points.

## Input

Use the user's supplied friction points. If none are provided, ask for 2-5 concrete issues from recent sessions before editing.

## Scope

Prefer active Codex and shared harness paths:

- `.codex/`
- `.agents/`
- `AGENTS.md` or provided global/project instructions

Read or edit `.claude/` only when the friction point is explicitly about Claude parity or a migration source.

## Workflow

1. Load relevant baseline instructions and config.
2. For each friction point, identify root cause:
   - Missing skill or stale command reference.
   - Hook schema mismatch.
   - Wrong permission rule or command path.
   - Broken plugin reference.
   - Bad YAML/TOML/frontmatter.
   - Contradictory instruction.
3. Create a concrete fix plan listing file, change, and prevented failure.
4. Apply only targeted edits. Preserve unrelated config.
5. Validate modified files:
   - TOML/JSON/YAML/frontmatter parses.
   - Referenced scripts or skills exist.
   - No Claude-only assumptions remain in active Codex config unless intentionally retained for migration parity.
6. Report:

   ```markdown
   ## Retrospective Report

   ### Friction Points
   - <issue> → <root cause> → <fix>

   ### Changes Made
   | File | Change | Prevents |
   |---|---|---|

   ### Validation
   - ...
   ```
