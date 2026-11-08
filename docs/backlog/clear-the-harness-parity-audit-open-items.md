# Clear the harness parity audit open items

Priority: Unprioritized

## Problem

`just harness-audit` reports 9 open items besides the `instructions.global` entry, which is filed as `load-shared-instructions-in-antigravity.md`. Each is a capability cell marked `partial` or `blocked` in `docs/agent-harnesses.json` (74 of the 315 registry cells are verified). The audit as of 2026-10-31:

```text
- skills.shared (antigravity): Verify agy imports and activates shared skill wrappers from the plugin
- skills.manual_only (antigravity): Verify Antigravity adapter excludes every procedural skill while continuing to emit ability skills
- commands.active (codex): Re-check Codex release notes for stable command format
- commands.active (crush): Re-check crush releases for a user-defined command surface, or teach the shared skill renderer to emit crush-specific user-invocable frontmatter
- agents.specialists (antigravity): Verify Antigravity can delegate to generated specialist wrappers with isolated context
- agents.specialists (crush): Re-check crush releases for user-defined agent support
- hooks.safety (antigravity): Verify Antigravity invokes hooks.json before shell/write/edit calls and blocks on deny
- hooks.safety (crush): Install crush and verify it blocks a denied shell command through the generated crushrc PreToolUse hook
- mcp.dependencies (codex): hand-add [mcp_servers.filesystem]; validated by just harness-check
```

## Outcome

None of the 9 items above appears under `## Open Items` in `just harness-audit`. Each one has been verified, fixed, or recorded as a permanent divergence.

## Notes

- [2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](../decisions/2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md) is still proposed. It drops Antigravity from the user-tier generator and reduces Codex and Crush to shared skills, `AGENTS.md`, and their guard shim. If it is accepted, every Antigravity cell and the command and agent cells for Codex and Crush stop being owed. Those cells should then become divergences or leave the registry rather than be verified. The `hooks.safety` check for Crush remains.
- The `agent-harness` workflow (`.github/workflows/agent-harness-parity.yml`) refreshes an open issue titled "Agent harness parity report" with the live audit. It searches open issues only, so with #362 closed it creates a new report issue instead of refreshing #362. Leave that new issue open; it is the live report.
- Imported from [#362](https://github.com/phatblat/dotfiles/issues/362).
