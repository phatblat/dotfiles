# Pi and OMP Session Usage Evidence

Use this reference before describing a Pi or OMP skill, plugin, extension, or MCP server as low-use, rarely used, stale, or safe to disable. Configuration proves that a component is available; it does not prove that the component ran.

## Safety boundary

Session data may contain prompts, source code, tool arguments and results, images, credentials, and other secrets. Keep analysis local and aggregate-only:

1. Resolve the active session roots before scanning.
2. Use a local deterministic scanner or query that streams records. Never load raw transcripts into model context or send them to an external API.
3. Extract only allowlisted identity and lifecycle fields. Discard all other fields immediately.
4. Emit counts, timestamps, coverage, and confidence—not transcript excerpts.
5. Keep the scan read-only. Never rewrite, move, or normalize session files during an audit.

Do not emit prompt text, assistant text, full tool arguments or results, working directories, images, blob references, secrets, or credentials. A local scanner may inspect only protocol-controlled identity fields such as a tool name, call ID, result status, skill name/path, or MCP provider metadata. For Pi's persisted explicit skill wrapper, inspect only the anchored `<skill name="…" location="…">` prefix and discard the rest of the message without emitting it.

Exclude these sources from the primary scan:

- Pi `auth.json`, `trust.json`, logs, and non-session state.
- OMP `agent.db`, `history.db`, `blobs/`, tool-artifact logs, and process logs.
- Model/token/cost statistics, including `omp stats`; they do not identify skill, MCP, or plugin invocations.

`history.db` is prompt history, not the complete tool or plugin event stream. Do not use it to claim that a component ran or did not run.

## Resolve the session roots

Record every root scanned and its retained timestamp range. If launch-time overrides are no longer discoverable, report that as a coverage gap rather than silently assuming the defaults.

### Pi 0.83.0

Resolve Pi's session directory in this order:

1. The active `--session-dir` CLI value.
2. `PI_CODING_AGENT_SESSION_DIR`.
3. `sessionDir` in the effective Pi settings.
4. `PI_CODING_AGENT_DIR/sessions`.

The normal fallback is `~/.pi/agent/sessions`. Pi settings may come from the user agent directory and a trusted project `.pi/settings.json`; resolve the same effective settings the audited launch used. A custom `sessionDir` is used directly and may flatten sessions into one directory, so recursively scan `*.jsonl` rather than assuming project buckets.

Historical launches may have used a different CLI value, environment, settings file, or agent root. Count only roots actually scanned and state that unlocated roots are outside coverage.

### OMP 17.2.6

An explicit session directory supplied by the CLI or client wins. Otherwise derive the data-backed sessions directory from the active profile and directory resolver:

- `OMP_PROFILE` selects a named profile; legacy `PI_PROFILE` is consulted only when `OMP_PROFILE` is undefined.
- A named profile derives its own agent directory and ignores `PI_CODING_AGENT_DIR`.
- The default profile honors `PI_CODING_AGENT_DIR`; otherwise its agent directory is `${HOME}/${PI_CONFIG_DIR:-.omp}/agent`.
- Without XDG migration, named profiles use `${HOME}/${PI_CONFIG_DIR:-.omp}/profiles/<profile>/agent/sessions`.
- On macOS and Linux, `XDG_DATA_HOME` is used only when the relevant app root already exists. The default becomes `$XDG_DATA_HOME/omp/sessions`; a named profile becomes `$XDG_DATA_HOME/omp/profiles/<profile>/sessions`. XDG flattens the `agent/` component.

The v17.2.6 `dirs.ts` header still says XDG is Linux-only, but the implementation checks both `linux` and `darwin` and requires the app or profile root to exist. Follow the implementation.

The normal default layout is:

```text
~/.omp/agent/sessions/<scope>-<project-basename>-<cwd-digest>/<timestamp>_<session-id>.jsonl
```

If a local installation contains nested subagent or advisor JSONL beneath a session-specific directory, include those files only when their location or lifecycle metadata identifies the role; do not assume that layout exists. Recursively scan only confirmed session `*.jsonl` roots, classify unknown files as unknown, and do not count adjacent `*.log` tool artifacts.

## Evidence rules

Keep discovery, invocation attempts, and successful results separate. Do not count a component merely because its name appears in startup instructions, a generated skill list, ordinary prose, compaction text, or capability enumeration.

| Resource | Confirmed evidence | Weaker evidence and caveats |
|---|---|---|
| Pi explicit skill | A persisted user message begins with Pi's generated `<skill name="…" location="…">` wrapper. Extract only `name` and `location` locally. | A skill name in ordinary message text is not evidence. |
| Pi model-loaded skill | An assistant `toolCall` reads the canonical `SKILL.md` or `skill://<name>`, joined to its `toolResult`. | A filesystem read proves loading, not necessarily successful completion of the workflow. Separate it from explicit invocation. |
| OMP explicit skill | A `custom_message` with `customType: "skill-prompt"`, user attribution, and `details.name`/`details.path`. | A discovered skill or prompt-list entry proves availability only. |
| OMP model-loaded skill | A `read` tool attempt targets the canonical skill path or `skill://` URL and has a corresponding result. | Count a failed read as an attempt, not successful use. |
| OMP MCP tool | A tool attempt/result maps to the configured server. Prefer result provenance such as `serverName`, `mcpToolName`, `provider`, or `providerName`; OMP-created names normally use `mcp_<server>_<tool>`. | A name prefix alone is only corroborated evidence when multiple providers or plugins could mint the same tool name. Startup, connection, discovery, and reconnect events are not invocations. |
| Pi MCP tool | Evidence defined by the installed MCP extension and mapped to that extension's tool/result schema. | Pi 0.83.0 has no built-in MCP provenance contract. Without an extension-specific mapping, report unknown rather than infer from a tool-name prefix. |
| Plugin or extension | A confirmed component invocation maps unambiguously to a currently installed plugin/extension source path or manifest entry. | Report component-level evidence. Hooks, system-prompt additions, renderers, and startup behavior may leave no invocation marker, so absence never proves the plugin was inactive. |

Treat tool lifecycle records as different observations of one call, not separate uses. Join a request and result by the stable call ID within the same session. If a lifecycle event, assistant tool call, and tool result all describe one call, count one attempt and at most one success or error.

Canonicalize skill paths and plugin roots in-process, including symlinks and project/user shadowing, but do not print private absolute paths. Keep same-named skills separate unless their canonical `SKILL.md` paths are identical. Map MCP calls to the effective server configuration for the session's harness and scope.

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
advisor_uses
first_seen
last_seen
evidence_kind
confidence
```

Use the session ID plus entry/call ID as the deduplication key. Count actor classes separately so agent-heavy sessions do not make a user-invoked workflow appear common. Keep failed attempts visible; repeated failures can be a stronger optimization signal than low volume.

Report the scan boundary alongside the aggregate:

- Pi and OMP versions.
- Resolved roots scanned, represented without private path details.
- Earliest and latest retained timestamps.
- Files parsed, files skipped, malformed records, and unknown record types.
- Any missing historical roots, disabled retention, schema uncertainty, or unmapped extensions.

## Interpret the result

Use these confidence labels:

- **Confirmed invocation** — an explicit skill marker or unambiguous tool request/result provenance.
- **Corroborated probable** — identity inferred from an installed mapping, but the retained record lacks canonical provenance.
- **Available/enabled only** — found in configuration, discovery, or startup context with no retained invocation evidence.
- **Unknown/not observed** — no applicable retained marker, incomplete coverage, or no reliable mapping.

Never convert `unknown/not observed` into `unused`. Prefer wording such as:

> No confirmed invocation was observed in 42 retained top-level sessions from 2026-07-01 through 2026-07-31; two nested attempts failed. Earlier sessions and hook-only behavior were outside coverage.

If the user asks for “rarely used,” define the threshold in the report and show the raw counts. Recommend disabling a skill or MCP server only after checking current configuration dependencies and failure impact. For a plugin or extension, inventory all contributed components first; an unobserved skill or MCP tool does not establish that its hooks, commands, renderers, or system-prompt behavior are unused.

## Version boundary

These rules are verified against Pi 0.83.0 and OMP 17.2.6. Recheck storage and event schemas before applying them to another release. Primary references:

- [Pi settings and session-directory precedence](https://github.com/earendil-works/pi-mono/blob/v0.83.0/packages/coding-agent/docs/settings.md)
- [Pi JSONL session format](https://github.com/earendil-works/pi-mono/blob/v0.83.0/packages/coding-agent/docs/session-format.md)
- [Pi skill expansion and persistence](https://github.com/earendil-works/pi-mono/blob/v0.83.0/packages/coding-agent/src/core/agent-session.ts)
- [OMP directory resolution](https://github.com/can1357/oh-my-pi/blob/v17.2.6/packages/utils/src/dirs.ts)
- [OMP session storage](https://github.com/can1357/oh-my-pi/blob/v17.2.6/docs/session.md)
- [OMP skill records](https://github.com/can1357/oh-my-pi/blob/v17.2.6/packages/coding-agent/src/extensibility/skills.ts)
- [OMP MCP naming and result provenance](https://github.com/can1357/oh-my-pi/blob/v17.2.6/packages/coding-agent/src/mcp/tool-bridge.ts)
