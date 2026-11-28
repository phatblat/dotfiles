# Re-research stale Codex, crush, and Pi capability cells

Priority: Low

## Problem

The 2026-11-26 audit corrected the `surface` text of three cells in `scripts/harness_capabilities.py` but left their `parity` values for the `harness-research` procedure, so they now contradict themselves:

- codex `permissions.rules` is `absent` beside a surface naming `prefix_rule` entries in `~/.codex/rules/*.rules`.
- crush `permissions.rules` is `absent` beside `permissions allow`/`deny` in crushrc.
- pi `mcp.dependencies` is `aligned` with artifact `~/.pi/agent/mcp.json`, which does not exist.

The crush skill-root premise, that `~/.agents/skills` is not a default root, is also still stated in the `skills.shared` crush cell, `docs/harness/skills.md`, and `.agentlink/providers/crush.toml`, although crush v0.102.0's README lists it as a default.

## Outcome

Each of those cells has a parity value that matches its surface and evidence, set through the `harness-research` skill, and `just harness-check` passes.

## Notes

- The docstring in `scripts/harness_capabilities.py` defines `absent` as no such surface.
