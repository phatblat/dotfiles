---
name: omp-hooks
description: Use when writing, debugging, or configuring an omp hook or extension — blocking or rewriting tool calls, redacting tool output, reshaping LLM context, registering tools/commands, or wiring modules through config.yml. Covers ExtensionAPI (current) vs HookAPI (legacy), the event catalog, discovery and load order, and disable controls. Not for Claude Code hooks (~/.claude/settings.json) or the shared harness safety guard (~/.agents/harness/hooks/).
---

# omp Hooks and Extensions

## Disambiguation — three different hook systems

This machine runs three unrelated things called "hooks". Confirm which one the
task means before editing anything:

| System | Lives in | Shape |
|---|---|---|
| **omp hooks/extensions** (this skill) | `~/.omp/agent/extensions/`, `<cwd>/.omp/extensions/` | TS/JS module, default-exported factory |
| Claude Code hooks | `~/.claude/settings.json` `hooks` | JSON event → shell command |
| Shared harness guard | `~/.agents/harness/hooks/` | Normalized cross-harness deny policy |

## Use `ExtensionAPI`, not `HookAPI`

`HookAPI` is the **legacy** API. The runtime now initializes the extension
runner: `--hook` is an alias for `--extension`, discovered `.ts`/`.js` hook
factories load as extension modules, and tools are wrapped by
`ExtensionToolWrapper` rather than `HookToolWrapper`.

`ExtensionAPI` is a superset — same event model, plus extension-only events
(`tool_execution_*`, `input`, `user_bash`, `user_python`, `mcp_notification`,
`before_provider_request`, `session_stop`, …), tool/command/renderer/provider
registration.

Write new work against `ExtensionAPI`. Reach for `HookAPI` only when
maintaining an existing hook module.

```ts
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

export default function myExtension(pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;
    if (!/\brm\s+-rf\s+\//.test(String(event.input.command ?? ""))) return;
    return { block: true, reason: "rm -rf / blocked by policy" };
  });
}
```

The default export must be a **function** (not a class). It may return a
promise; the loader awaits it.

## The two contracts you will use most

### Block or rewrite a tool call — `tool_call`

Returns `{ block?, reason?, input? }`.

- Any handler returning `block: true` stops execution immediately (first block
  short-circuits). `reason` becomes the error text the model sees.
- **A handler that throws also blocks — the wrapper fails closed.** Do not let
  incidental exceptions through unless blocking is what you want.
- Returning `input` replaces the raw execution arguments. Handlers do not see
  each other's revisions (last non-blocking return wins), it is ignored when
  `block` is true, and it never applies to `computer` calls.

### Patch a tool result — `tool_result`

Returns `{ content?, details?, isError? }`.

- **Ordering differs by API:** under `ExtensionAPI` this is middleware-style —
  each handler sees prior handlers' modifications. Under `HookAPI` every
  handler sees the original event and the last return wins.
- `isError` is typed but `HookToolWrapper` does not apply it; on tool failure
  the original error is rethrown after handlers run.
- `tool_result` still fires with `isError: true` when the tool failed.

### Reshape context — `context`

Returns `{ messages? }`, fires before each LLM call, chained (each handler
receives the previous handler's output). Return nothing to pass through.

## Where modules live and what wins

Load order, deduped by absolute path, **first seen wins**:

1. Native auto-discovered — `<cwd>/.omp/extensions`, `~/.omp/agent/extensions`
2. Discovered `.ts`/`.js` hook-capability factories
3. Installed plugin entries (`package.json` `omp.extensions`)
4. Explicit configured paths — CLI `-e/--extension`/`--hook` first, then
   settings `extensions`

A module both auto-discovered and explicitly configured loads once, at the
auto-discovered position.

Config (user `~/.omp/agent/config.yml`, project `<cwd>/.omp/config.yml`):

```yaml
extensions:
  - ~/my-exts/safety.ts
  - ./local/ext-pack
disabledExtensions:
  - extension-module:foo # derived from entry path: /x/foo.ts -> foo
```

Disable controls: `--no-extensions` (explicit `-e`/`--hook` paths still load),
`disabledExtensions` by capability id. Full precedence, profile paths, and
directory-resolution rules are in `references/configuration.md`.

## Pitfalls that actually bite

- **Runtime actions are unavailable during load.** Calling `pi.sendMessage()`
  from the factory throws `ExtensionRuntimeNotInitializedError`. Register in
  the factory; act from events, commands, and tools.
- **Extensions are not sandboxed — they share the process.** A raw
  `setInterval`/`setTimeout`/detached-promise callback that throws escapes
  handler dispatch, becomes an `uncaughtException`, and the postmortem handler
  tears down **the whole session**. Use `ctx.setInterval` / `ctx.setTimeout` /
  `ctx.clearTimer`: same signatures, contained failures, `unref`'d, and cleared
  on `session_shutdown`.
- **`appendEntry` customType is a global namespace.** Use a reverse-domain key
  (`com.example.my-ext.state`) and avoid core-reserved values.
- **Gitignore applies unevenly.** Native auto-discovery globs with
  `gitignore: true, hidden: false`; explicit configured-directory scanning uses
  `readdir` and applies no gitignore filtering.
- **Directory scanning is one level deep.** No recursion past a single
  subdirectory; `index.ts` wins over `index.js`.
- Command names colliding with built-ins are skipped with diagnostics, and
  reserved shortcuts (`ctrl+c`, `escape`, `enter`, …) are ignored.
- Guard every interactive call — `ctx.hasUI` is `false` in headless, print, and
  subagent modes.

## References

- `references/event-catalog.md` — every event, when it fires, what it returns
- `references/configuration.md` — discovery roots, profiles, precedence,
  disable ids, layout examples

Authoritative upstream docs ship with the installed omp and are version-matched;
read them directly rather than trusting the website (which is a client-rendered
SPA and returns no content to a fetch):

- `omp://extensions.md` — ExtensionAPI reference
- `omp://extension-loading.md` — discovery and loading
- `omp://hooks.md` — legacy hook subsystem internals
- `omp://skills/authoring-hooks.md` — authoring guide
- `omp://skills/examples/safety-hook/README.md` — worked example
