---
name: optimize
description: Audit Codex and agent harness configuration for efficiency, redundant work, permission friction, hook overhead, plugin cost, and dead config. Use when invoked as `$optimize` or when the user asks to optimize the agent harness.
---

# optimize

Audit the active Codex/agent harness for performance bottlenecks, redundant work, missing permissions, and stale configuration. If the user provides a focus area, narrow the review to it: `hooks`, `permissions`, `plugins`, or `all`.

## Audit scope

Prefer active Codex paths:

- `.codex/config.toml`
- `.codex/hooks.json`
- `.codex/hooks/scripts/`
- `.agents/skills/`
- `.agents/harness/`
- `~/.codex/` plugin and skill metadata when relevant

Read `.claude/` only for migration parity or when the user explicitly asks about legacy Claude Code behavior.

## Audit dimensions

### Hooks

For each active hook:

- Event and matcher frequency.
- Script cost, spawned interpreters, filesystem scans, network calls.
- Whether stdout/stderr shape matches Codex hook expectations.
- Whether the hook fails open or closed.
- Timeout and state-file behavior.

Flag hot-path hooks that do too much work or still assume Claude transcript/tool JSON.

### Permissions and approvals

Review recurring command patterns that likely cause unnecessary prompts:

- Git/GitHub CLI operations.
- Search/navigation tools.
- Build/test/format tools.
- Node/Python scripts used by Codex skills and hooks.

Recommend specific allow rules only when they are meaningfully safe and scoped.

### Plugins and skills

Check enabled plugins and active skills for:

- Duplicate functionality.
- Disabled plugins still wired into hooks.
- Large always-loaded instructions.
- Legacy slash-command names that should be skill names.
- Broken references to removed Claude commands or paths.

### MCP servers

Check configured MCP servers for high timeouts, disabled-but-stale entries, missing commands, or servers that are always connected but rarely used.

### Context budget

Review global/project instructions, session-start output, and skill descriptions for verbosity or stale references.

## Output

Return a prioritized report:

```markdown
## Harness Optimization Report

### Critical
| # | Issue | Impact | Fix |
|---|---|---|---|

### High
| # | Issue | Impact | Fix |
|---|---|---|---|

### Low
| # | Issue | Impact | Fix |
|---|---|---|---|

### Already Good
- ...
```

After reporting, ask which fixes to implement. Do not mutate config during the audit unless the user asked for implementation.
