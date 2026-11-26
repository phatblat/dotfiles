# Restore or retire the boris skill

Priority: Low

## Problem

`.agents/skills/boris/SKILL.md` (34,872 bytes) is Claude Code guidance with the product names mechanically replaced: it has 19 `.Codex` paths and tells the reader to run `Codex --agent=`. It was imported in `1a61743`. The 2026-11-26 audit observed no read or invocation of it in 901 OMP session files over 30 days.

## Outcome

The skill either describes the right product for each harness that loads it, or it is deleted.

## Notes

- The skill was hidden by the 2026-11-26 audit: its `agents/openai.yaml` flag hides it from Codex, the Claude wrapper, and the Antigravity adapter.
- `tests/agent-harnesses.bats` lists `boris` in `procedural_skills`, so the change that retires the skill must remove that entry.
