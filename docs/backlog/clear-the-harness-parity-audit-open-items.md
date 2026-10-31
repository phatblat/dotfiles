# Clear the harness parity audit open items

Priority: Unprioritized

## Problem

`just harness-audit` reports 17 open items besides the two `instructions.global` entries, which are filed as `load-shared-instructions-in-antigravity-and-cursor.md`. Each is a capability cell marked `partial` or `blocked` in `docs/agent-harnesses.json` (92 of the 405 registry cells are verified). The audit as of 2026-10-31:

```text
- skills.shared (antigravity): Verify agy imports and activates shared skill wrappers from the plugin
- skills.shared (cursor): Verify Cursor discovers and activates the shared skills
- skills.manual_only (antigravity): Verify Antigravity adapter excludes every procedural skill while continuing to emit ability skills
- commands.active (codex): Re-check Codex release notes for stable command format
- commands.active (crush): Re-check crush releases for a user-defined command surface, or teach the shared skill renderer to emit crush-specific user-invocable frontmatter
- commands.active (cursor): Verify Cursor discovers all 25 generated command wrappers
- commands.active (grok): Add a shared skill for the linear/progress workflow so grok covers all 25 command workflows
- agents.specialists (antigravity): Verify Antigravity can delegate to generated specialist wrappers with isolated context
- agents.specialists (crush): Re-check crush releases for user-defined agent support
- agents.specialists (cursor): Verify Cursor discovers generated specialist agent wrappers
- agents.specialists (grok): Verify grok spawn_subagent can launch the generated specialist profiles
- hooks.safety (antigravity): Verify Antigravity invokes hooks.json before shell/write/edit calls and blocks on deny
- hooks.safety (crush): Install crush and verify it blocks a denied shell command through the generated crushrc PreToolUse hook
- hooks.safety (cursor): Confirm in a live Cursor session that a protected-path write is blocked
- hooks.safety (grok): Verify grok blocks a denied shell command through ~/.grok/hooks/harness-guard.json in a live session
- mcp.dependencies (codex): hand-add [mcp_servers.filesystem]; validated by just harness-check
- sessions.compaction (cursor): Verify Cursor resume and history behavior against compact-preservation requirements
```

## Outcome

None of the 17 items above appears under `## Open Items` in `just harness-audit`. Each one has been verified, fixed, or recorded as a permanent divergence.

## Notes

- [2026-10-12-consolidate-harness-parity-on-omp-and-claude-code](../decisions/2026-10-12-consolidate-harness-parity-on-omp-and-claude-code.md) is still proposed. It drops Antigravity and Cursor from the user-tier generator and reduces Codex, Crush, and Grok to shared skills, `AGENTS.md`, and their guard shim. If it is accepted, every Antigravity and Cursor cell and the command and agent cells for Codex, Crush, and Grok stop being owed. Those cells should then become divergences or leave the registry rather than be verified. The `hooks.safety` checks for Crush and Grok remain.
- The `agent-harness` workflow (`.github/workflows/agent-harness-parity.yml`) refreshes an open issue titled "Agent harness parity report" with the live audit. It searches open issues only, so with #362 closed it creates a new report issue instead of refreshing #362. Leave that new issue open; it is the live report.
- Imported from [#362](https://github.com/phatblat/dotfiles/issues/362).
