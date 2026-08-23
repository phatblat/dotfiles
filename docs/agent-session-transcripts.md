# Agent Session Transcripts

## Purpose and boundary

This document is the durable record of where each supported agent harness
keeps its session history on disk, and what those records look like. It
documents **on-disk layout only**. The privacy and evidence rules that
govern how a scanner may use this layout live in
`~/.agents/skills/optimize-harness/references/session-usage-evidence.md`,
and the executable implementation that reads these formats is
`~/scripts/harness-sessions.py`. The harness inventory data referenced
throughout (slugs, labels, CLI binaries, config roots, session-store
descriptors) lives in `~/scripts/harness_paths.py`.

`~/.gemini/antigravity-cli/conversations/*` is guard-protected
(`~/.agents/harness/hooks/safety.py:71`, `PROTECTED_PATHS`) and is never
read by any tooling described here, even though it is technically part of
the Antigravity session store.

## Store summary

| slug | CLI binary | config root(s) | session store | store kind |
|---|---|---|---|---|
| `claude` | `claude` | `~/.claude` | `~/.claude/projects/*/*.jsonl` + `~/.claude/history.jsonl` (prompts only, out of scope) | jsonl |
| `codex` | `codex` | `~/.codex` | `~/.codex/sessions/**/rollout-*.jsonl` | jsonl |
| `opencode` | `opencode` | `~/.config/opencode` | `~/.local/share/opencode/opencode.db` | sqlite |
| `pi` | `pi` | `~/.pi/agent` | `~/.pi/agent/sessions/*.jsonl` | jsonl |
| `omp` | `omp` | `~/.omp/agent` | `~/.omp/agent/sessions/**/*.jsonl` | jsonl |
| `antigravity` | `agy` | `~/.gemini` + `~/.agents/harness/adapters/antigravity` | `~/.gemini/antigravity-cli/history.jsonl` only; `conversations/*.pb` is protobuf and guard-protected | jsonl + opaque |
| `cursor` | `cursor-agent` | `~/.cursor` (blanket-gitignored) + `~/.agents/harness/adapters/cursor` | `~/.cursor/projects/*/agent-transcripts/*/*.jsonl` | jsonl |
| `grok` | `grok` | `~/.grok` | `~/.grok/sessions/<url-encoded-cwd>/<id>/{chat_history,events,updates}.jsonl` + `sessions/session_search.sqlite` (not read) | jsonl |

## Per-harness sections

### claude

**Resolved root.** `CLAUDE_CONFIG_DIR` would relocate the root, but this
override was not confirmed from CLI output this session; `harness-sessions.py`
resolves it when set and records the resolution source either way, defaulting
to `~/.claude`.

**File layout.** One file per top-level session at
`~/.claude/projects/<url-encoded-cwd>/<session-uuid>.jsonl`, one JSON object
per line. Nested subagent transcripts sit at
`<session-uuid>/subagents/agent-<id>.jsonl` under the same session
directory — the scanner globs `projects/**/*.jsonl` recursively to catch
them; each record in a subagent file already carries `isSidechain: true`
and `agentId` itself, so no extra depth/filename-based classification is
needed (unlike OMP, where subagent files must be identified by filename
shape). `~/.claude/history.jsonl` holds raw prompt text only
(`{display, pastedContents, timestamp, project, sessionId}`) with no tool
events, and is out of scope for usage/friction reporting.

**Record schema.** Top-level `type` ∈ `attachment | assistant | user |
last-prompt | custom-title | pr-link | mode | queue-operation | system`, each
record carrying `timestamp`, `isSidechain`, and often `agentId` (subagent
markers).

- `tool_call` / `tool_result`: `message.content[]` entries with
  `type == "tool_use"` (`name` from `.name`; observed `Bash`, `Edit`, `Read`,
  `Write`, `Skill`, `AskUserQuestion`, `Agent`, `SendMessage`, `ToolSearch`,
  `mcp__*`) and `type == "tool_result"` (`{tool_use_id, type, content,
  is_error}`, joined by `tool_use_id`). `is_error` is absent on roughly a
  third of results — absent maps to unknown (`None`), never to success. A
  `name` starting `mcp__` is classified `mcp_call`.
- `skill_invoke`: `tool_use` with `name == "Skill"` (`input.skill`), and
  `attachment.type == "invoked_skills"` (`skills[].name`).
- `hook_run`: `attachment.type == "hook_success"`, always carrying
  `{hookName, hookEvent, exitCode, durationMs, command, toolUseID, stdout,
  stderr, content}`. This is the highest-value signal in the whole store —
  measured per-firing hook cost, not guessed from script source. Emitted
  name is `f"{hookEvent}:{hookName}"`; `hookName` frequently already embeds
  the event (e.g. `PostToolUse:Bash`), so the emitted name doubles the
  prefix (`PostToolUse:PostToolUse:Bash`) — expected, not a bug.
- `permission_state`: `attachment.type == "command_permissions"`
  (`{type, allowedTools, model}`; one record per `allowedTools` entry).
- `cache_miss`: `message.diagnostics.cache_miss_reason.type` ∈
  `system_changed | model_changed | previous_message_not_found | unavailable
  | messages_changed`.
- `compaction`: record `subtype` ∈ `stop_hook_summary | compact_boundary`.
- `subagent` actor: record-level `isSidechain == true` or non-null
  `agentId`.

**Observed volume.** 42 session files locally (35 top-level, 7 nested
subagent transcripts); a 3201-line top-level sample session alone carried
264 tool_use/tool_result pairs, 1662 `hook_success` records, 23
`cache_miss` records, and 5 compaction boundaries.

**Out of coverage.** `history.jsonl` prompt text; hook `command`/`stdout`/
`stderr`/`content` fields (dropped at the source, only `hookEvent`,
`hookName`, `exitCode`, `durationMs` survive).

### codex

**Resolved root.** `CODEX_HOME` confirmed present in `codex --help`; highest
precedence, else `~/.codex`.

**File layout.** `~/.codex/sessions/<year>/<month>/<day>/
rollout-<timestamp>-<uuid>.jsonl`, one JSON object per line with top-level
`{timestamp, type, payload}`.

**Record schema.** `type` ∈ `session_meta | event_msg | response_item |
turn_context | world_state | inter_agent_communication_metadata |
compacted`. `payload.type` ∈ `message | user_message | agent_message |
reasoning | agent_reasoning | token_count | task_started | task_complete |
custom_tool_call | custom_tool_call_output | function_call |
function_call_output | mcp_tool_call_end | patch_apply_end |
tool_search_call | tool_search_output | web_search_end | turn_aborted |
context_compacted | thread_settings_applied | sub_agent_activity`.

- `tool_call` / `tool_result`: `payload.type` ∈ `custom_tool_call |
  function_call` (name from `payload.name`, observed `exec`; id
  `payload.call_id`) joined with `custom_tool_call_output |
  function_call_output` by `call_id`. Codex carries no structured success
  field on the output, so `ok` is always `None` here — regexing `output`
  text for the word "error" would be inference dressed as evidence, and is
  deliberately not done.
- `mcp_call`: `payload.type == "mcp_tool_call_end"`.
- `turn_abort`: `payload.type == "turn_aborted"`
  (`{turn_id, reason, completed_at, duration_ms, started_at}`).
- `compaction`: `payload.type == "context_compacted"` or record
  `type == "compacted"`.
- `permission_state`: `type == "turn_context"` →
  `payload.permission_profile.type` (observed `managed`) and
  `payload.sandbox_policy.type` (observed `read-only`).
- `subagent` actor: `payload.type == "sub_agent_activity"`, or record type
  `inter_agent_communication_metadata`.

**Observed volume.** 433 rollout files locally; a 67-line sample carried 5
`custom_tool_call`/5 `custom_tool_call_output` pairs and 5 `web_search_end`
events.

**Out of coverage.** No output success/failure signal (by design, not a
scanner limitation).

### opencode

**Resolved root.** `XDG_DATA_HOME` would relocate the root; not confirmed
from CLI output this session. Default `~/.local/share/opencode/opencode.db`
(SQLite).

**File layout.** Single SQLite database. Relevant tables: `session`,
`message`, `part`, each storing a JSON blob in a `data` TEXT column. The
`session_message` table exists but is empty locally, and `permission` has 0
rows. There is no `part.type` column — the discriminator lives inside the
JSON blob. The scanner opens the database read-only via a temp-file copy
(`file:...?mode=ro`) so a live harness process is never locked or mutated.

**Record schema.** `part.data` keys: `{type, text, snapshot, time, reason,
tokens, cost, tool, callID, state, hash, files, synthetic, metadata, mime,
filename, url, source}`; `state` sub-keys `{status, input, time, output,
metadata, title, error}`.

- `tool_call` / `tool_result`: `data.type == "tool"` is a single self-contained
  record (no separate call/result join needed) — `name = data.tool`, id
  `data.callID`, `ok = data.state.status == "completed"`, `False` when
  `status == "error"` (`state.error` present). Observed `state.status` ∈
  `completed | error`. Duration comes from `state.time.{start,end}`
  (epoch milliseconds).
- `turn_abort`: `data.type == "step-finish"` with `data.reason == "length"`;
  observed `reason` ∈ `stop | tool-calls | length | unknown`.
- `message.data` keys `{role, time, agent, parentID, mode, path, cost,
  tokens, modelID, providerID, model, summary, finish, error, variant}` →
  actor from `role`; `parentID` set marks a subagent message.

**Observed volume.** 1230 session rows but only 37 messages / 58 parts
locally — report this as low coverage, not as opencode features being
unused.

### pi

**Resolved root.** `PI_CODING_AGENT_SESSION_DIR` then
`PI_CODING_AGENT_DIR`, confirmed present; else `~/.pi/agent`.

**File layout.** `~/.pi/agent/sessions/<timestamp>_<uuid>.jsonl`, one JSON
object per line, top-level `type` ∈ `session | message | model_change |
thinking_level_change`, each `message`-typed record carrying `timestamp`.

**Record schema.**

- `tool_call`: `message.content[].type == "toolCall"` (name from `.name`;
  observed `bash`, `read`, `edit`, `harness_agent_registry`; id from `.id`).
- `tool_result`: `message.role == "toolResult"` (`name =
  message.toolName`, id `message.toolCallId`, `ok = not message.isError`,
  `isError` present directly on the message).
- `skill_invoke`: a user message whose text begins with Pi's anchored
  `<skill name="…" location="…">` wrapper — only the `name` attribute is
  extracted, the wrapped instruction body is discarded unread.
- `skill_read`: a `toolCall` to `read` whose target path ends `SKILL.md` or
  starts `skill://` — only the skill name path shape is inspected, never the
  read result content.

**Observed volume.** 19 session files locally.

### omp

**Resolved root.** `OMP_PROFILE`, then `PI_CODING_AGENT_DIR`, then
`PI_CONFIG_DIR`, then `XDG_DATA_HOME`, confirmed present; else
`~/.omp/agent`.

**File layout.** `~/.omp/agent/sessions/<workspace-dir>/
<timestamp>_<session-id>.jsonl` for the top-level session. Nested subagent
transcripts sit **beside the parent** under the same session directory tree
at variable depth (e.g. `<session-dir>/<AgentName>.jsonl` or one level
deeper) — the scanner globs `sessions/**/*.jsonl` recursively to catch every
depth, then classifies `actor="subagent"` purely from filename shape: only
the exact `<timestamp>_<session-id>.jsonl` top-level form is `"assistant"`,
anything else under `sessions/` is a subagent transcript. Top-level `type` ∈
`message | custom | custom_message | model_change | thinking_level_change |
title_change | title | session | credential_pin | service_tier_change |
mode_change | compaction`, each record carrying `timestamp`.

**Record schema.**

- `tool_call`: `type == "custom"` with `customType == "tool_execution_start"`
  (`data.toolName`, id `data.toolCallId`, start `data.startedAt`). Observed
  names: `bash`, `read`, `hub`, `edit`, `grep`, `todo`, `write`, `task`,
  `web_search`, `eval`, `ask`, `glob`, `verify_syntax`, `git-commit`.
- `tool_result`: `type == "message"` with `message.role == "toolResult"`
  (`name = message.toolName`, id `message.toolCallId`,
  `ok = not message.isError`). Duration is the result record's `timestamp`
  minus the matching call's `data.startedAt`.
- `skill_invoke`: `type == "custom_message"` with
  `customType == "skill-prompt"` (`details.name`; other `details` keys
  `{path, args, lineCount}` are not read).
- `compaction`: `type == "compaction"`.
- `turn_abort`: `type == "custom"` with `customType == "session_exit"`
  (`detail = data.reason`; observed `dispose`, `sighup`).

**Observed volume.** 460 jsonl files locally across top-level and nested
subagent transcripts.

### antigravity

**Resolved root.** No env override confirmed; `~/.gemini`.

**File layout.** `~/.gemini/antigravity-cli/history.jsonl` only. Keys
`{display, timestamp, workspace, conversationId}` — prompt count and date
range only, no tool events.
`~/.gemini/antigravity-cli/conversations/*.pb` is protobuf with no
published schema and is on the guard's protected-path list; transcript
bodies are permanently out of coverage, not merely unimplemented.

**Observed volume.** 1 history file locally, 128 bytes, single prompt.

### cursor

**Resolved root.** No env override confirmed; `~/.cursor` (this root is
also blanket-gitignored, see `~/.gitignore:255`).

**File layout.** `~/.cursor/projects/<project-slug>/agent-transcripts/
<session-uuid>/<session-uuid>.jsonl` — note the session-id appears as both a
directory and the filename inside it.

**Record schema.** Anthropic-shaped: `{role, message, type, status}` with
`message.content[].type` ∈ `text | tool_use` and `type == "turn_ended"`
carrying `status` (observed `success`).

- `tool_call`: `tool_use` `.name`.
- `turn_abort`: `turn_ended.status != "success"`.

**Observed volume.** Single local transcript file — expect a low-coverage
report.

### grok

**Resolved root.** No env override confirmed; `~/.grok`.

**File layout.** `~/.grok/sessions/<url-encoded-cwd>/<session-id>/` holding
three files plus a shared index:

- `chat_history.jsonl`: `{type, content, synthetic_reason}`,
  `type` ∈ `system | user | assistant`. No tool records — this file yields
  only a `session_start` observation.
- `events.jsonl` — the valuable file:
  `{ts, type, server_name, transport, target, timeout_sec, duration_ms,
  servers[], tool_count, tools, error_type, error_message, enabled,
  disabled, total_servers, succeeded, failed, auth_required, total_tools,
  is_reinit, failed_servers}`, `type` ∈ `mcp_server_starting |
  mcp_server_connected | mcp_server_failed | mcp_config_resolved |
  mcp_init_completed | yolo_toggled`. `mcp_lifecycle` records use
  `name = server_name`, `ms = duration_ms`, `ok` derived from the event
  type, `detail = error_type` — `error_message` free text is never emitted.
- `updates.jsonl`: `{timestamp, method, params}`; only
  `params.update.sessionUpdate` and `params.update.currentModeId` are safe
  discriminators (not currently emitted; noted for future extension).
- `sessions/session_search.sqlite` is an FTS index over the same transcript
  text as the files above — deliberately never read.

**Observed volume.** 1 session directory locally
(`%2FUsers%2Fphatblat/01a00630-753b-7302-88b9-ffec523354f4`), 2 files
(`chat_history.jsonl`, `events.jsonl`).

## Observed volumes

Scanned 2026-08-23 with `~/scripts/harness-sessions.py --since 3650
--max-files 1000` (all-time window, cap raised past every local tree size)
and `just harness-audit` for CLI versions:

| Harness | CLI version | Files on disk | Files parsed | Earliest retained | Latest retained |
|---|---|---|---|---|---|
| claude | 2.1.236 (Claude Code) | 42 (35 top-level, 7 nested subagent) | 42 | 2026-07-07 | 2026-08-23 |
| codex | codex-cli 0.149.0 | 433 | 433 | 2026-06-27 | 2026-08-18 |
| opencode | 1.18.20 | 1 db, 1230 sessions / 37 messages / 58 parts | 1 db | 2026-06-02 | 2026-06-08 |
| pi | 0.84.2 | 19 | 19 | 2026-06-27 | 2026-08-12 |
| omp | omp/18.0.0 | 460 | 460 | 2026-08-02 | 2026-08-23 |
| antigravity | 1.0.13 | 1 | 1 | 2026-05-25 | 2026-05-25 |
| cursor | 2026.07.01-777f564 | 1 | 1 | (no ts field observed) | (no ts field observed) |
| grok | grok 1.0.5 (5115b46bc909) [alpha] | 1 session dir, 2 files | 2 | 2026-08-15 | 2026-08-15 |

`harness-sessions.py`'s default `--max-files` is 400; `codex` is the only
harness whose on-disk tree exceeds that default (433 files), so a default
scan of `codex` reports 400 parsed, not 433. Every other harness's local
tree is smaller than the default cap.

## How this was determined

Every count above came from a read-only probe that never printed free-text
field values, re-runnable after any harness upgrade:

1. Enumerate each root's session files with `find`/`glob` and count them.
2. Load a representative sample file (largest available, or the single file
   when only one exists) and parse every line as JSON.
3. Tally the top-level `type` (and, where present, `payload.type` /
   `data.type` / `attachment.type`) key paths with a `collections.Counter`,
   printing only the enum values and their counts.
4. For fields documented as small closed enums (`is_error`,
   `state.status`, `sandbox_policy.type`, …), print the distinct observed
   values and their counts, never the surrounding free-text fields.
5. For SQLite stores, connect read-only (`file:...?mode=ro`) and run
   `select count(*)` per table plus `select data from part/message limit N`
   to inspect blob shape, then close the connection.
6. Record CLI versions with `<binary> --version`, matching what
   `command_audit` in `scripts/agent-harnesses.py` already collects via
   `just harness-audit`.

Re-running this probe after a harness upgrade is the way to detect a schema
drift before `harness-sessions.py` silently under-counts a harness — a
new/renamed `type` value shows up as an unexpectedly small count relative to
file volume, which is the signal to re-open this document.
