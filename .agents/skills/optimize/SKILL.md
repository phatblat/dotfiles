---
name: optimize
description: Audit Codex and shared agent harness configuration for efficiency, redundant work, permission friction, hook overhead, plugin cost, skill metadata portability, and dead config. Use when invoked as `$optimize`, when the user asks to optimize the agent harness, or when porting shared skills, commands, agents, hooks, or MCP config between agent tools.
---

# optimize

Audit the active Codex/agent harness for performance bottlenecks, redundant work, missing permissions, and stale configuration. If the user provides a focus area, narrow the review to it: `hooks`, `permissions`, `plugins`, or `all`.

## Audit scope

Prefer active Codex paths:

- `.codex/config.toml`
- `.codex/hooks.json`
- `.codex/hooks/scripts/`
- `.agents/skills/`
- `.agents/skills/*/agents/openai.yaml`
- `.agents/skills/optimize/references/agent-harness-portability.md`
- `.agents/harness/`
- `~/.codex/` plugin and skill metadata when relevant

Read `.claude/` only for migration parity or when the user explicitly asks about legacy Claude Code behavior.
For cross-agent porting or metadata questions, read `references/agent-harness-portability.md`.

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
- Skills that should be classified as **procedural** or **ability**:
  - **Procedural** skills are user-run workflows, interactive interviews, migrated commands, or procedures that should run only when explicitly invoked (for example, `$git-commit`, `$optimize`, `$grilling`).
  - **Ability** skills are reusable model-invoked capabilities or domain rules Codex should apply automatically when the task matches (for example, code review standards, docs lookup, platform-specific implementation guidance).
- For procedural skills, check for `agents/openai.yaml` with:

  ```yaml
  policy:
    allow_implicit_invocation: false
  ```

- Do not describe `allow_implicit_invocation: false` as removing the skill from context. It only prevents implicit invocation; enabled skill metadata can still appear in Codex's initial skill list. If a rarely used procedural skill should not appear in context at all, recommend disabling it via `[[skills.config]] enabled = false` or moving it out of scanned skill paths.
- Do not recommend creating a separate `classify-skill` skill unless the rubric is reused by multiple workflows. If it is created for model use, treat it as an ability; if it is only a command the user runs, treat it as procedural.

### Harness portability

When optimizing shared skills or porting harness features between Claude, Codex, OpenCode, Pi, Antigravity, and Cursor:

1. Classify each skill as **procedural** or **ability** before mapping metadata.
2. Keep portable `SKILL.md` frontmatter minimal: `name` and `description` first. Treat fields such as `allowed-tools`, `disable-model-invocation`, `paths`, model hints, and UI metadata as harness-specific unless the target's primary docs confirm support.
3. Put Codex-specific behavior in `agents/openai.yaml`, especially `policy.allow_implicit_invocation` and `dependencies.tools`.
4. Front-load skill descriptions with the trigger and boundary so shortened skill lists still classify correctly.
5. Move long details into `references/`, deterministic repeat work into `scripts/`, and output resources into `assets/`.
6. Record unsupported or unverified harness metadata as an adapter gap instead of copying stale keys across tools.
7. When porting research changes current agent configuration facts, update `ATTRIBUTE_MAPPINGS` in `scripts/agent-harnesses.py`, regenerate `docs/agent-harnesses.*`, and update `references/agent-harness-portability.md` in the same change.

Use `references/agent-harness-portability.md` for the current attribute mapping and source notes.

### MCP servers

Check configured MCP servers for high timeouts, disabled-but-stale entries, missing commands, or servers that are always connected but rarely used.

### Context budget

Review global/project instructions, session-start output, and skill descriptions for verbosity or stale references.

### Tracked configuration coverage

Harness config roots in the dotfiles repo are allowlist-governed: `.gitignore`
denies `<root>/*` and re-includes named paths with `!`. That fails safe — a new
credential file is ignored by default — but it also means a genuinely new
config file never appears in `git status`. Nothing prompts you to track it.

Close that blind spot with:

```bash
just audit-ignored-config           # all curated harness roots
just audit-ignored-config .omp .pi  # narrow to specific roots
```

The script classifies every ignored, untracked file under those roots as
secret, runtime state, vendored package content, or config candidate, and
reports only the candidates plus two hazards: config-shaped files carrying
credential material, and already-tracked files that look like credentials.

Triage each candidate:

- **Track it** — hand-authored and portable across machines. Add a `!` rule to
  `~/.gitignore` in sorted position, then re-run `~/scripts/sort-gitignore`.
- **Dismiss it** — installed, bundled, or machine-generated. Vendored skill
  bundles and a harness's own bundled system skills are the common case; they
  reinstall on any new machine and tracking them just forks upstream.
- **Extend the classifier** — if a whole directory of runtime state keeps
  surfacing, add its name to `STATE_DIRS` in `~/scripts/audit-ignored-config.py`
  rather than dismissing it by hand every audit.

Never propose tracking these, whatever the report says:

| Class | Examples | Why |
|---|---|---|
| Credential stores | `.omp/agent/agent.db`, `.pi/agent/auth.json`, `*.env` | OAuth tokens and API keys |
| Secret definitions | `.omp/agent/secrets.yml`, `secret-placeholder.key` | Plaintext secrets and their HMAC key |
| Trust grants | `.pi/agent/trust.json`, `.config/homebrew/trust.json` | A per-machine security decision. Replicating it auto-approves on a fresh host a directory you only vetted on one machine — a privilege escalation dressed as config. |
| Machine identity | `.omp/install-id` | Per-install UUID; copying it merges telemetry identities |
| Transcripts | `sessions/`, `history.db`, `blobs/` | May contain anything typed or read |

Flag any hit in the "tracked files that look like credentials" section as
**Critical** in the report, even if it turns out to be a false positive from a
test fixture or an `.env.example`.

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
