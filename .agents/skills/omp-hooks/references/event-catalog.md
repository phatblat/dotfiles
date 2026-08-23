# omp Event Catalog

Every event the extension/hook runtime emits, when it fires, and what a handler
may return. Events marked **ext-only** require `ExtensionAPI`; the rest are
available to both `ExtensionAPI` and legacy `HookAPI`.

Canonical types live in `src/extensibility/extensions/types.ts` (extensions) and
`src/extensibility/hooks/types.ts` (legacy hooks).

## Tool lifecycle

| Event | Fires | Can return |
|---|---|---|
| `tool_call` | Before every tool execution | `{ block?: boolean; reason?: string; input?: Record<string, unknown> }` |
| `tool_result` | After every tool execution | `{ content?; details?; isError?: boolean }` |
| `tool_execution_start` **ext-only** | Execution begins | — (observability) |
| `tool_execution_update` **ext-only** | Streaming update | — (observability) |
| `tool_execution_end` **ext-only** | Execution ends | — (observability) |
| `tool_approval_requested` **ext-only** | Tool requires approval and an approval handler is registered | — (observability) |
| `tool_approval_resolved` **ext-only** | Approval resolved | — (observability) |

For model-issued calls under `ExtensionAPI`, `tool_call` fires at arg-prep time
in the agent loop, so an `input` revision is revalidated and observed by
concurrency scheduling, execution events, the persisted assistant message, and
the approval gate alike.

## Session lifecycle

| Event | Fires | Can return |
|---|---|---|
| `session_start` | Initial session load | — |
| `session_before_switch` | Before session switch | `{ cancel?: boolean }` |
| `session_switch` | After session switch | — |
| `session_before_branch` | Before branch | `{ cancel?: boolean; skipConversationRestore?: boolean }` |
| `session_branch` | After branch | — |
| `session_before_compact` | Before compaction | `{ cancel?: boolean; compaction?: CompactionResult }` |
| `session.compacting` | During compaction | `{ context?: string[]; prompt?: string; preserveData?: Record<string, unknown> }` |
| `session_compact` | After compaction | — |
| `session_before_tree` | Before tree navigation | `{ cancel?: boolean; summary?: { summary: string; details?: unknown } }` |
| `session_tree` | After tree navigation | — |
| `session_shutdown` | Session shutdown | — |

Note the punctuation inconsistency: `session.compacting` uses a dot, every
other session event uses underscores.

## Prompt, turn, and agent lifecycle

| Event | Fires | Can return |
|---|---|---|
| `input` **ext-only** | User input submitted | — |
| `before_agent_start` | Before the agent starts a turn | `{ message?: { customType; content; display; details; attribution? } }` |
| `before_provider_request` **ext-only** | Before the provider request | may replace the request payload |
| `after_provider_response` **ext-only** | After the provider response | — |
| `context` | Before each LLM API call | `{ messages?: Message[] }` |
| `agent_start` | Agent streaming starts | — |
| `agent_end` | Agent streaming ends | — (notification-only) |
| `session_stop` **ext-only** | Main-session stop, awaited before settle | `{ continue: true, additionalContext }` or `{ decision: "block", reason }` |
| `turn_start` | Start of a user→agent turn | — |
| `turn_end` | End of a user→agent turn | — |
| `message_start` **ext-only** | Message begins | — |
| `message_update` **ext-only** | Message updates | — |
| `message_end` **ext-only** | Message ends | — (detached snapshot) |

`before_provider_request` is fired by every provider except `devin-agent`.

`session_stop` is capped at 8 consecutive continuations and never fires for
task/subagent sessions.

`message_end` receives a **detached** message snapshot — mutating it changes
nothing. Use `tool_result` or `context` to alter what reaches the provider.

## Reliability and runtime signals

| Event | Fires |
|---|---|
| `auto_compaction_start` / `auto_compaction_end` | Auto-compaction boundaries |
| `auto_retry_start` / `auto_retry_end` | Auto-retry boundaries |
| `ttsr_triggered` | Too-short-response retry triggered |
| `todo_reminder` | Todo reminder fires |
| `goal_updated` **ext-only** | Goal changed |
| `credential_disabled` **ext-only** | A credential was disabled |

## MCP

| Event | Fires | Payload |
|---|---|---|
| `mcp_notification` **ext-only** | Every JSON-RPC notification from a connected MCP server | `{ server: string; method: string; params: unknown }` |

Fires **after** the manager handles known list/update methods
(`notifications/tools/list_changed`, `notifications/resources/list_changed`,
`notifications/resources/updated`, `notifications/prompts/list_changed`).
Unknown and server-custom methods are delivered too. Multiple extensions may
subscribe, and one throwing handler does not stop the others. Notifications
that arrive before any listener attaches are buffered (bounded FIFO, cap 100,
drop-oldest) and drained into the first subscriber, so startup frames survive an
extension that binds after MCP discovery.

## User command interception

| Event | Fires | Can return |
|---|---|---|
| `user_bash` **ext-only** | User runs a bash command directly | `{ result }` |
| `user_python` **ext-only** | User runs Python directly | `{ result }` |

## `resources_discover`

Present in extension types and implemented as
`ExtensionRunner.emitResourcesDiscover(...)`, but there are no `AgentSession`
callsites invoking it in the current codebase. Do not build on it.

## Conflict resolution by event

| Event | Multiple handlers |
|---|---|
| `tool_call` | First `block: true` short-circuits; otherwise last return wins. `input` revisions are last-wins and handlers do not observe each other's |
| `tool_result` | `ExtensionAPI`: middleware — each handler sees prior modifications. `HookAPI`: last return wins, no short-circuit |
| `context` | Chained — each handler receives the previous handler's messages |
| `before_agent_start` | First returned message is kept; later ones ignored |
| `session_before_*` | Latest result tracked; `cancel: true` short-circuits immediately |
| `session.compacting` | Latest result wins |

Handler order is deterministic: extension/hook array order, then registration
order within each module.

Command and renderer lookups are first-match-wins across modules
(`getCommand`, `getMessageRenderer`); `getRegisteredCommands()` returns all
without dedupe.

## Error propagation

- **Load time** — an invalid module or missing default export is captured as a
  structured `{ path, error }`; other modules keep loading.
- **Event time** — `ExtensionRunner` and `HookRunner.emit(...)` catch handler
  errors, report them on the error channel, and continue.
- **`emitToolCall(...)` is stricter** — handler errors are not swallowed. They
  propagate and the wrapper blocks the tool call. Fail-closed by design.
