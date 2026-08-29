---
name: optimize-harness
description: Audit one or all supported agent harnesses (claude, codex, opencode, pi, omp, antigravity, cursor, grok) for config efficiency, hook overhead, permission friction, plugin and MCP cost, skill metadata portability, dead config, and measured session friction. Use when invoked as `$optimize-harness [harness ...] [focus]`, or when the user asks to optimize or compare agent harness configuration.
---

# optimize-harness

Audit one or all supported agent harnesses for performance bottlenecks,
redundant work, missing permissions, stale configuration, and measured
session friction. Produce a prioritized, multi-harness report.

## Argument contract

Whitespace-split `$ARGUMENTS`. Order-independent, no positional meaning:

- A token in `{claude, codex, opencode, pi, omp, antigravity, cursor, grok}`
  adds that harness to the target set. None given means all eight.
- A token in `{config, hooks, permissions, plugins, mcp, context, sessions,
  friction, all}` sets the focus. None given means `all`.
- `since:N` sets the session window in days for the friction scan, default
  `30`.
- Any other token: stop and print the two valid token sets above. Do not
  guess a fuzzy match.

Example: `$optimize-harness claude hooks since:14` resolves to `{claude}` +
focus `hooks` + a 14-day session window, with no clarifying question.

## Resolution step

Read `references/harness-map.md` for the per-harness config root, CLI
binary, and known gotchas. For each target harness, check whether its CLI
binary and config root exist. A harness whose root is absent is reported as
`not installed / not configured` and skipped — it is never rendered as an
empty finding.

## Control-plane note

`scripts/agent-harnesses.py`, `scripts/agent_plugins.py`,
`.agents/harness/hooks/`, and `.agents/harness/generated-paths.json` are
human-only (`~/.agents/harness/hooks/safety.py:89-100`,
`_CONTROL_PLANE_FRAGMENTS`). A fix that lands in one of them must be
reported as a hand-patch for the user to apply, never attempted directly —
this prevents every future run from rediscovering the same deny.

## Execution shape

1. Run one deterministic scan first:
   `python3 ~/scripts/harness-sessions.py <slugs> --since <N> --json`, and
   use its output as the **only** source of usage and friction claims. Read
   `references/session-usage-evidence.md` before describing any component as
   low-use, rarely used, stale, or safe to disable — it defines the
   confidence labels and evidence rules this skill must follow.
2. Audit static config per harness (see Audit dimensions below). Fan out
   config audits to subagents in batches of at most 3 concurrent (the shared
   harness instructions cap parallel subagents at 3), each subagent
   returning one harness's findings; merge into a single report.
3. Never let a subagent read raw transcripts — subagents consume only the
   scanner's JSON output, never transcript files directly. This keeps the
   privacy boundary in `references/session-usage-evidence.md` enforced
   structurally, not by instruction alone.

## Audit dimensions

Each dimension is stated per harness, not just for Claude.

### Hooks

For each active hook (Claude `~/.claude/settings.json`; Codex
`~/.codex/hooks.json`; OMP/Pi/other harnesses per
`references/harness-map.md`):

- Event and matcher frequency — cross-reference against
  `harness-sessions.py`'s `## Hook cost` section (Claude only) for measured
  firing counts and p50/p95 duration, not guessed cost.
- Script cost, spawned interpreters, filesystem scans, network calls.
- Whether the hook fails open or closed, and its timeout.
- Whether stdout/stderr shape matches the harness's hook expectations.

Flag hot-path hooks that do too much work. Before flagging any hook as
redundant or overly broad, check `git log --oneline -- <hook script>` in the
dotfiles repo for prior `optimize:`/`fix:` commits — a hook that looks like
duplicated overhead may already be a deliberately tuned guard around an
external tool's fixed event contract. `references/harness-map.md` records
one known-good exception researched this way; do not re-flag it.

### Permissions and approvals

Review recurring command patterns that likely cause unnecessary prompts:
git/GitHub CLI operations, search/navigation tools, build/test/format
tools, and harness-specific scripts. Recommend specific allow rules only
when they are meaningfully safe and scoped. `references/harness-map.md`
lists the permission command families investigated for Claude; extend per
harness as audited.

### Plugins and skills

Check enabled plugins and active skills for: duplicate functionality,
disabled plugins still wired into hooks, large always-loaded instructions,
legacy command names that should be skill names, and broken references to
removed paths.

Classify each skill as **procedural** or **ability**:

- **Procedural** skills are user-run workflows, interactive interviews,
  migrated commands, or procedures that should run only when explicitly
  invoked (for example, `$git-commit`, `$optimize-harness`).
- **Ability** skills are reusable model-invoked capabilities or domain rules
  the harness should apply automatically when the task matches.

For procedural skills, check for `agents/openai.yaml` with:

```yaml
policy:
  allow_implicit_invocation: false
```

Do not describe `allow_implicit_invocation: false` as removing the skill
from context — it only prevents implicit invocation; enabled skill metadata
can still appear in a harness's initial skill list. If a rarely used
procedural skill should not appear in context at all, recommend disabling
it via harness-specific config (`[[skills.config]] enabled = false` for
Codex) or moving it out of scanned skill paths. Do not recommend creating a
separate `classify-skill` skill unless the rubric is reused by multiple
workflows.

### MCP servers

Check configured MCP servers per harness for high timeouts, disabled-but-
stale entries, missing commands, or servers that connect on every session
but are rarely called — cross-reference against the scanner's `mcp_call`
and `mcp_lifecycle` observations rather than guessing from config alone.

### Context budget

Review global/project instructions, session-start output, and skill
descriptions for verbosity or stale references, per harness.

### Harness portability

When optimizing shared skills or porting harness features between the
eight supported harnesses, read `references/agent-harness-portability.md`
for the current attribute mapping and source notes:

1. Classify each skill as **procedural** or **ability** before mapping
   metadata.
2. Keep portable `SKILL.md` frontmatter minimal: `name` and `description`
   first. Treat `allowed-tools`, `disable-model-invocation`, `paths`, model
   hints, and UI metadata as harness-specific unless the target's primary
   docs confirm support.
3. Put harness-specific behavior in its native sidecar (Codex
   `agents/openai.yaml`; OMP local adapter; etc. — see
   `references/harness-map.md`).
4. Front-load skill descriptions with the trigger and boundary so
   shortened skill lists still classify correctly.
5. Move long details into `references/`, deterministic repeat work into
   `scripts/`, and output resources into `assets/`.
6. Record unsupported or unverified harness metadata as an adapter gap
   instead of copying stale keys across tools.
7. When porting research changes current agent configuration facts, update
   `CAPABILITIES` in `scripts/harness_capabilities.py`, regenerate
   `docs/agent-harnesses.*` and `docs/harness/` via `just harness-generate`,
   and update `references/agent-harness-portability.md` in the same change.
   The `harness-research` skill is the full per-release procedure.

### Session friction (measured)

Use `python3 ~/scripts/harness-sessions.py <slugs> --since <N> --json`
(already run in step 1 of Execution shape) for:

- Tool error rates and which tools/skills/MCP servers actually ran, per
  `references/session-usage-evidence.md`'s confidence labels.
- Aborted turns and their reasons.
- Cache-miss reasons (Claude).
- MCP connection failures.
- Hook cost (Claude only): firings, total/p50/p95 ms, non-zero exits.

Never render `unknown/not observed` as `unused`.

### Tracked configuration coverage

Harness config roots in the dotfiles repo are allowlist-governed:
`.gitignore` denies `<root>/*` and re-includes named paths with `!`. That
fails safe — a new credential file is ignored by default — but it also
means a genuinely new config file never appears in `git status`. Nothing
prompts you to track it.

Close that blind spot with:

```bash
just audit-ignored-config              # all curated harness roots
just audit-ignored-config .omp .pi     # narrow to specific roots
```

The script classifies every ignored, untracked file under those roots as
secret, runtime state, vendored package content, or config candidate, and
reports only the candidates plus two hazards: config-shaped files carrying
credential material, and already-tracked files that look like credentials.

Triage each candidate:

- **Track it** — hand-authored and portable across machines. Add a `!` rule
  to `~/.gitignore` in sorted position, then re-run `~/scripts/sort-gitignore`.
- **Dismiss it** — installed, bundled, or machine-generated. Vendored skill
  bundles and a harness's own bundled system skills are the common case;
  they reinstall on any new machine and tracking them just forks upstream.
- **Extend the classifier** — if a whole directory of runtime state keeps
  surfacing, add its name to `STATE_DIRS` in
  `~/scripts/audit-ignored-config.py` rather than dismissing it by hand
  every audit.

Never propose tracking these, whatever the report says:

| Class | Examples | Why |
|---|---|---|
| Credential stores | `.omp/agent/agent.db`, `.pi/agent/auth.json`, `*.env` | OAuth tokens and API keys |
| Secret definitions | `.omp/agent/secrets.yml`, `secret-placeholder.key` | Plaintext secrets and their HMAC key |
| Trust grants | `.pi/agent/trust.json`, `.config/homebrew/trust.json` | A per-machine security decision. Replicating it auto-approves on a fresh host a directory you only vetted on one machine — a privilege escalation dressed as config. |
| Machine identity | `.omp/install-id` | Per-install UUID; copying it merges telemetry identities |
| Transcripts | `sessions/`, `history.db`, `blobs/` | May contain anything typed or read |

Flag any hit in the "tracked files that look like credentials" section as
**Critical** in the report, even if it turns out to be a false positive
from a test fixture or an `.env.example`.

## Output

```markdown
## Harness Optimization Report

### Coverage
| Harness | Version | Config root | Sessions scanned | Window | Gaps |
|---|---|---|---|---|---|

### Critical
| # | Harness | Issue | Evidence | Impact | Fix |
|---|---|---|---|---|---|

### High
| # | Harness | Issue | Evidence | Impact | Fix |
|---|---|---|---|---|---|

### Low
| # | Harness | Issue | Evidence | Impact | Fix |
|---|---|---|---|---|---|

### Already Good
- ...
```

The `Evidence` column must cite a scanner counter (e.g. "2942 `Bash`
PostToolUse firings, p95 219ms") or a config path. A finding with no
evidence is dropped, not softened.

After reporting, ask which fixes to implement. Do not mutate config during
the audit.
