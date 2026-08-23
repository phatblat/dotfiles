# Session Usage and Friction Evidence

Use this reference before describing any skill, plugin, extension, MCP
server, or tool as low-use, rarely used, stale, safe to disable, or a
friction source, for any of the eight supported harnesses. Configuration
proves that a component is available; it does not prove that the component
ran. This file owns **policy** only: record schemas live in
`docs/agent-session-transcripts.md`, and the implementation that enforces
this policy is `~/scripts/harness-sessions.py`.

## Safety boundary

Session data may contain prompts, source code, tool arguments and results,
images, credentials, and other secrets. Keep analysis local and
aggregate-only:

1. Resolve the active session roots before scanning.
2. Use a local deterministic scanner that streams records
   (`~/scripts/harness-sessions.py`). Never load raw transcripts into model
   context or send them to an external API.
3. Extract only allowlisted identity and lifecycle fields. Discard all other
   fields immediately — the scanner's `emit()` chokepoint enforces this
   structurally (≤64 chars, no newline, no free-text field).
4. Emit counts, timestamps, coverage, and confidence — not transcript
   excerpts.
5. Keep the scan read-only. Never rewrite, move, or normalize session
   files during an audit. SQLite stores are copied to a temp file before
   opening read-only, so a live harness is never locked or mutated.

Do not emit prompt text, assistant text, full tool arguments or results,
working directories, images, blob references, secrets, or credentials. The
scanner may inspect only protocol-controlled identity fields such as a tool
name, call ID, result status, skill name/path, or MCP provider metadata.
For Pi's persisted explicit skill wrapper, inspect only the anchored
`<skill name="…" location="…">` prefix and discard the rest of the message
without emitting it.

Exclude these sources from the primary scan:

- Pi `auth.json`, `trust.json`, logs, and non-session state.
- OMP `agent.db`, `history.db`, `blobs/`, tool-artifact logs, and process
  logs.
- Claude `history.jsonl` (raw prompt text, no tool events).
- Grok `session_search.sqlite` (FTS index over the same transcript text as
  `events.jsonl`/`chat_history.jsonl`, not an additional source).
- Antigravity `conversations/*.pb` (protobuf with no published schema, and
  on the guard's protected-path list, `safety.py:71`).
- Model/token/cost statistics; they do not identify skill, MCP, or plugin
  invocations.

## Resolve the session roots

Record every root scanned and its retained timestamp range. If launch-time
overrides are no longer discoverable, report that as a coverage gap rather
than silently assuming the defaults. `~/scripts/harness_paths.py`'s
`SESSION_STORES` holds the resolution order and `verified` flag per
harness; `~/scripts/harness-sessions.py` applies it and records which
source resolved.

### Pi

Resolve Pi's session directory in this order:

1. The active `--session-dir` CLI value.
2. `PI_CODING_AGENT_SESSION_DIR`.
3. `sessionDir` in the effective Pi settings.
4. `PI_CODING_AGENT_DIR/sessions`.

The normal fallback is `~/.pi/agent/sessions`. Pi settings may come from the
user agent directory and a trusted project `.pi/settings.json`; resolve the
same effective settings the audited launch used. A custom `sessionDir` is
used directly and may flatten sessions into one directory, so recursively
scan `*.jsonl` rather than assuming project buckets.

Historical launches may have used a different CLI value, environment,
settings file, or agent root. Count only roots actually scanned and state
that unlocated roots are outside coverage.

### OMP

An explicit session directory supplied by the CLI or client wins. Otherwise
derive the data-backed sessions directory from the active profile and
directory resolver:

- `OMP_PROFILE` selects a named profile; legacy `PI_PROFILE` is consulted
  only when `OMP_PROFILE` is undefined.
- A named profile derives its own agent directory and ignores
  `PI_CODING_AGENT_DIR`.
- The default profile honors `PI_CODING_AGENT_DIR`; otherwise its agent
  directory is `${HOME}/${PI_CONFIG_DIR:-.omp}/agent`.
- Without XDG migration, named profiles use
  `${HOME}/${PI_CONFIG_DIR:-.omp}/profiles/<profile>/agent/sessions`.
- On macOS and Linux, `XDG_DATA_HOME` is used only when the relevant app
  root already exists. The default becomes `$XDG_DATA_HOME/omp/sessions`; a
  named profile becomes `$XDG_DATA_HOME/omp/profiles/<profile>/sessions`.
  XDG flattens the `agent/` component.

The normal default layout is:

```text
~/.omp/agent/sessions/<scope>-<project-basename>-<cwd-digest>/<timestamp>_<session-id>.jsonl
```

Nested subagent JSONL sits beside the parent under the same session
directory tree at variable depth
(`docs/agent-session-transcripts.md#omp`). Classify a file as a subagent
transcript purely from filename shape — only the exact
`<timestamp>_<session-id>.jsonl` top-level form is the parent session — not
from directory depth alone.

### claude, codex, opencode, antigravity, cursor, grok

Root resolution and any env-var overrides for these six harnesses are
documented per-slug in `docs/agent-session-transcripts.md`, with each
override's `verified` status. `CODEX_HOME` is confirmed present in
`codex --help`; the rest (`CLAUDE_CONFIG_DIR`, `XDG_DATA_HOME` for
opencode, and no confirmed override for grok/cursor/antigravity) were not
confirmable from primary CLI output this session — `harness-sessions.py`
still resolves them when set and records the resolution source, so an
unconfirmed override degrades to a coverage note, never a silent miss.

## Evidence rules

Keep discovery, invocation attempts, and successful results separate. Do
not count a component merely because its name appears in startup
instructions, a generated skill list, ordinary prose, compaction text, or
capability enumeration.

| Resource | Confirmed evidence | Weaker evidence and caveats |
|---|---|---|
| Pi explicit skill | A persisted user message begins with Pi's generated `<skill name="…" location="…">` wrapper. Extract only `name` and `location` locally. | A skill name in ordinary message text is not evidence. |
| Pi model-loaded skill | An assistant `toolCall` reads the canonical `SKILL.md` or `skill://<name>`, joined to its `toolResult`. | A filesystem read proves loading, not necessarily successful completion of the workflow. Separate it from explicit invocation. |
| OMP explicit skill | A `custom_message` with `customType: "skill-prompt"`, user attribution, and `details.name`/`details.path`. | A discovered skill or prompt-list entry proves availability only. |
| OMP model-loaded skill | A `read` tool attempt targets the canonical skill path or `skill://` URL and has a corresponding result. | Count a failed read as an attempt, not successful use. |
| Claude skill | `tool_use` with `name == "Skill"` (`input.skill`), or an `invoked_skills` attachment (`skills[].name`). | A skill mentioned in prose or a plugin listing is not evidence. |
| OMP MCP tool | A tool attempt/result maps to the configured server. Prefer result provenance such as `serverName`, `mcpToolName`, `provider`, or `providerName`; OMP-created names normally use `mcp_<server>_<tool>`. | A name prefix alone is only corroborated evidence when multiple providers or plugins could mint the same tool name. Startup, connection, discovery, and reconnect events are not invocations. |
| Claude MCP tool | `tool_use`/`tool_result` `name` prefixed `mcp__`. | Prefix alone is corroborated, not confirmed, when multiple plugins could mint the same server name. |
| Codex MCP tool | `payload.type == "mcp_tool_call_end"`. | Codex records no structured output for regular tool calls either; never infer success/failure from free text. |
| Grok MCP server | `events.jsonl` `mcp_server_connected`/`mcp_server_failed` records, joined by `server_name`. | `mcp_server_starting` alone is a lifecycle attempt, not a confirmed connection. |
| Pi MCP tool | Evidence defined by the installed MCP extension and mapped to that extension's tool/result schema. | Pi has no built-in MCP provenance contract as of this version. Without an extension-specific mapping, report unknown rather than infer from a tool-name prefix. |
| Plugin or extension | A confirmed component invocation maps unambiguously to a currently installed plugin/extension source path or manifest entry. | Report component-level evidence. Hooks, system-prompt additions, renderers, and startup behavior may leave no invocation marker, so absence never proves the plugin was inactive. |

Treat tool lifecycle records as different observations of one call, not
separate uses. Join a request and result by the stable call ID within the
same session. If a lifecycle event, assistant tool call, and tool result all
describe one call, count one attempt and at most one success or error —
`harness-sessions.py`'s `CallJoiner` enforces this per harness.

Canonicalize skill paths and plugin roots in-process, including symlinks and
project/user shadowing, but do not print private absolute paths. Keep
same-named skills separate unless their canonical `SKILL.md` paths are
identical. Map MCP calls to the effective server configuration for the
session's harness and scope.

## Friction signals

Alongside usage evidence, the scanner reports friction — problems, not just
presence:

| Signal | Source | What it means |
|---|---|---|
| Tool error rate | `ok == False` share of a `(harness, kind, name)` group | A tool or MCP call that fails often is worth investigating before it is worth recommending against. |
| Hook cost (Claude only) | `hook_run` records: firings, total/p50/p95 ms, non-zero exits | Measured, not guessed, per-hook cost — replaces reading hook script source to estimate overhead. |
| Aborted turns | `turn_abort` records, grouped by `detail` (reason) | Codex `turn_aborted.reason`, OpenCode `step-finish` with `reason == "length"`, Cursor `turn_ended.status != "success"`. |
| Cache misses (Claude only) | `cache_miss` records, grouped by `detail` | `system_changed`, `model_changed`, `previous_message_not_found`, `unavailable`, `messages_changed` — repeated misses under one reason point at a specific fix (e.g. `system_changed` means something in the always-loaded system prompt churns between turns). |
| MCP connection failures | Grok `mcp_lifecycle` records with `ok == False`; Claude/Codex/OMP MCP tool call errors | A server that fails to connect wastes the harness's startup time whether or not it is ever called. |

Never diagnose friction from a single low-volume sample — cross-reference
against `distinct_sessions` and the coverage window before recommending a
fix.

## Aggregate without double-counting

For each resource, collect only:

```text
resource_type
resource_name
provider_or_plugin
attempts
successes
errors
distinct_sessions
top_level_uses
subagent_uses
first_seen
last_seen
p50_ms
p95_ms
evidence_kind
confidence
```

Use the session ID plus call ID as the deduplication key. Count actor
classes separately so agent-heavy sessions do not make a user-invoked
workflow appear common. Keep failed attempts visible; repeated failures can
be a stronger optimization signal than low volume.

Report the scan boundary alongside the aggregate:

- CLI versions for every scanned harness (from `just harness-audit`).
- Resolved roots scanned, represented without private path details.
- Earliest and latest retained timestamps.
- Files parsed, files skipped, malformed records, and unknown record types.
- Any missing historical roots, disabled retention, schema uncertainty, or
  unmapped extensions.

## Interpret the result

Use these confidence labels:

- **Confirmed invocation** — an explicit skill marker or unambiguous tool
  request/result provenance.
- **Corroborated probable** — identity inferred from an installed mapping,
  but the retained record lacks canonical provenance.
- **Available/enabled only** — found in configuration, discovery, or
  startup context with no retained invocation evidence.
- **Unknown/not observed** — no applicable retained marker, incomplete
  coverage, or no reliable mapping.

Never convert `unknown/not observed` into `unused`. Prefer wording such as:

> No confirmed invocation was observed in 42 retained top-level sessions
> from 2026-07-01 through 2026-07-31; two nested attempts failed. Earlier
> sessions and hook-only behavior were outside coverage.

If the user asks for "rarely used," define the threshold in the report and
show the raw counts. Recommend disabling a skill or MCP server only after
checking current configuration dependencies and failure impact. For a
plugin or extension, inventory all contributed components first; an
unobserved skill or MCP tool does not establish that its hooks, commands,
renderers, or system-prompt behavior are unused.

## Version boundary

These rules are verified against the following CLI versions
(`just harness-audit`, 2026-08-24):

| Harness | Version |
|---|---|
| claude | 2.1.236 (Claude Code) |
| codex | codex-cli 0.149.0 |
| opencode | 1.18.21 |
| pi | 0.84.2 |
| omp | omp/18.0.3 |
| antigravity | 1.0.13 |
| cursor | 2026.07.01-777f564 |
| grok | grok 1.0.5 (5115b46bc909) [alpha] |

omp (18.0.0 → 18.0.3) and opencode (1.18.20 → 1.18.21) advanced since the
prior check-in. Both are patch releases; not re-verified against upstream
source, but the 2026-08-23 scan of these two versions parsed every retained
file with zero malformed records and zero unknown record types, which is
corroborating (not exhaustive) evidence the session/event schema held.

Recheck storage and event schemas before applying these rules to another
release — a schema drift shows up as an unexpectedly small observation
count relative to file volume (see
`docs/agent-session-transcripts.md#how-this-was-determined` for the
re-check procedure). Primary references for Pi/OMP root resolution:

- [Pi settings and session-directory precedence](https://github.com/earendil-works/pi-mono/blob/v0.84.2/packages/coding-agent/docs/settings.md)
- [Pi JSONL session format](https://github.com/earendil-works/pi-mono/blob/v0.84.2/packages/coding-agent/docs/session-format.md)
- [Pi skill expansion and persistence](https://github.com/earendil-works/pi-mono/blob/v0.84.2/packages/coding-agent/src/core/agent-session.ts)
- [OMP directory resolution](https://github.com/can1357/oh-my-pi/blob/v18.0.0/packages/utils/src/dirs.ts)
- [OMP session storage](https://github.com/can1357/oh-my-pi/blob/v18.0.0/docs/session.md)
- [OMP skill records](https://github.com/can1357/oh-my-pi/blob/v18.0.0/packages/coding-agent/src/extensibility/skills.ts)
- [OMP MCP naming and result provenance](https://github.com/can1357/oh-my-pi/blob/v18.0.0/packages/coding-agent/src/mcp/tool-bridge.ts)
