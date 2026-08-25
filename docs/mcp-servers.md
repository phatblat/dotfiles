# MCP servers by harness

No inventory of which MCP servers were configured where existed before this
file (checked 2026-08-25 while resolving an `optimize-harness` audit finding).
Config-file scanning alone under-counts what a harness actually connects to:
several harnesses **discover** MCP servers from other tools' config files or
from installed plugins, so "configured in `~/.grok/config.toml`" and
"connects for grok" are different questions. Keep both columns below in sync
by hand when a server is added/removed; there is no automated check yet.

## Current state (post `optimize-harness` cleanup, 2026-08-25)

| Harness | Explicitly configured (own files) | Discovered/inherited | Notes |
|---|---|---|---|
| claude | none (`~/.claude/mcp.json`: `{}`) | — | `context-mode`, `tolaria` removed this session (see History) |
| codex | `computer-use`, `node_repl`, `notion`, `openaiDeveloperDocs`, `orch` (all enabled); `RepoPrompt` (`enabled = false`) — all in `~/.codex/config.toml` `[mcp_servers.*]` | — | `context-mode` (was `enabled = false`) and the dead `kyto64-...` marketplace/plugin removed this session |
| omp | none (`~/.omp/agent/mcp.json`: `{}`) | Claude Code (`~/.claude.json`, `~/.claude/mcp.json`), Claude marketplace plugins' own `.mcp.json` (e.g. `oh-my-claudecode`'s `t` server), Codex, Gemini CLI, OpenCode, Cursor, Windsurf, VS Code, root `mcp.json`/`.mcp.json` — priority order in `omp://mcp-config.md#discovery-and-precedence` | `context-mode` removed from the explicit entry this session. `t` (oh-my-claudecode bridge, 54 tools) and the native-looking `filesystem`/`memory`/`node_repl` tool families are **not** externally configured anywhere — see "OMP's `mcp__*` tool families" below |
| pi | none (`packages: ["npm:context-mode"]` removed this session; nothing else declared an MCP server) | — | — |
| grok | none (`~/.grok/config.toml` has zero `[mcp_servers.*]` blocks) | `[compat.claude].mcps = true` → scans `~/.claude.json`; `[compat.cursor].mcps = true` → scans `~/.cursor/mcp.json`; also discovers installed Claude-plugin-bundled servers (e.g. `oh-my-claudecode`'s `t`, previously `context-mode`) | Root cause of the `tolaria`/`github` findings in the original audit: grok never configures servers itself, it inherits whatever Claude Code and Cursor have. Verify with `grok mcp doctor --json` |
| antigravity | `~/.gemini/config/mcp_config.json` is empty (0 bytes) | unknown — no documented compat-scan mechanism found for antigravity-cli | Separate from the top-level Gemini CLI (`~/.gemini/settings.json`), which is a different tool sharing the `.gemini/` parent directory and did have `tolaria` (removed) |
| opencode | none found (`~/.config/opencode/opencode.jsonc` has no `mcp` key) | unknown | Confirmed in the original audit as a real gap, not a coverage blind spot — opencode has no MCP servers at all currently |
| cursor | none (`~/.cursor/mcp.json`: `{}`) | — | `tolaria` removed this session |

Also cleared: the shared cross-tool registry `~/.config/mcp/mcp.json` (only ever held `tolaria`) and the top-level Gemini CLI's `~/.gemini/settings.json` (also only `tolaria`) — neither is harness-specific, both feed the compat-scan/import mechanisms above.

## OMP's `mcp__*` tool families — what's real, what's native

Three tool-name families that look like external MCP servers on inspection turned out to be OMP's own compiled-in implementations, not spawned subprocess connections:

| Family | Origin | Evidence |
|---|---|---|
| `mcp__filesystem_*` | **OMP-native.** No config file, no installed plugin `.mcp.json`, no npm `package.json` anywhere on this machine declares a `filesystem` MCP server. Tool names/shapes mirror the official `@modelcontextprotocol/server-filesystem` package's surface, suggesting an in-process reimplementation rather than a spawned subprocess (matches `omp://mcp-config.md`'s own filesystem example server name, but no such entry exists in any discovered config here). | Exhaustive search: `~/.omp/agent/mcp.json`, `~/.claude.json`, `~/.claude/mcp.json`, every `.mcp.json` under `~/.claude/plugins/cache/**`, every `package.json` under `~/.omp/plugins/node_modules/*` — zero matches |
| `mcp__memory_*` | **OMP-native**, same evidence as filesystem (mirrors `@modelcontextprotocol/server-memory`'s knowledge-graph tool surface) | Same exhaustive search, zero matches |
| `mcp__node_repl_*` (`js`, `js_reset`, `js_add_node_module_dir`) | **OMP-native** JS REPL tool. Do not confuse with **Codex's** `mcp_servers.node_repl`, a real external stdio server (`/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node_repl`, a ChatGPT desktop app binary for browser/computer-use) — same name, two unrelated implementations in two different harnesses | Codex's is a literal `command =` path in `~/.codex/config.toml`; OMP's has no equivalent config anywhere |
| `mcp__oh_my_claudecode_t_*` (54 tools) | **Real external server**, genuinely discovered — not native. Declared by the installed Claude Code plugin `oh-my-claudecode` at `~/.claude/plugins/cache/omc/oh-my-claudecode/<version>/.mcp.json` as a single server named `t` (`node .../bridge/mcp-server.cjs`), which OMP imports via its documented "Claude marketplace plugins" discovery tier (priority 4, per `omp://mcp-config.md`). All 54 tools are namespaced under that one server. | `~/.claude/plugins/cache/omc/oh-my-claudecode/4.15.7/.mcp.json`; confirmed live via `grok mcp doctor --json` → `"source": "plugin: oh-my-claudecode"`, `"name": "t"`, `"54 tools discovered"` |
| `mcp__context_mode_*` | Was a **real external server** (`bun .../context-mode/server.bundle.mjs`, explicitly declared in `~/.omp/agent/mcp.json`) — removed this session, see History | `~/.omp/agent/mcp.json` (now empty) |

## Discovery mechanisms per harness (how a server gets found without being configured there)

- **OMP**: documented, ordered discovery across 9 provider tiers — see `omp://mcp-config.md#discovery-and-precedence`. First definition wins; duplicates are not merged.
- **grok**: `[compat.claude]`/`[compat.cursor]` toggles in `~/.grok/config.toml` (default: on) scan `~/.claude.json` and `~/.cursor/mcp.json` respectively, plus installed Claude-plugin `.mcp.json` files. Verify what grok currently sees with `grok mcp doctor --json` (also runs a live connectivity check per server) or `grok mcp list`.
- **claude, codex, pi, cursor, opencode, antigravity**: no cross-tool discovery observed during this audit — each reads only its own config file(s). (Not exhaustively verified for antigravity/opencode beyond "no MCP servers currently present to discover".)

## Keeping this current

There is no scripted check yet. When adding/removing an MCP server:

1. Update the server's own harness config file as usual.
2. Update the relevant row/cell in the "Current state" table above.
3. If the change affects a server another harness might inherit (anything in `~/.claude.json`, `~/.cursor/mcp.json`, or an installed Claude plugin), spot-check with `grok mcp doctor --json` and re-run `codex plugin marketplace list` / `claude plugin list` as applicable, since grok and OMP both inherit transitively.

## History

- 2026-08-25: Removed `tolaria` (stale `mise` node path, broken app bundle) from `~/.claude.json`, `~/.cursor/mcp.json`, `~/.config/mcp/mcp.json`, `~/.gemini/settings.json`. Removed `context-mode` everywhere: uninstalled the Claude Code plugin (`claude plugin uninstall context-mode` + `claude plugin marketplace remove context-mode`), removed the dead `context-mode-cache-heal.mjs` SessionStart hook, removed the OMP `mcp.json` entry, removed Codex's disabled plugin entry, removed Pi's `npm:context-mode` package. Removed the dead `kyto64-codex-pr-review-toolkit-minimal` marketplace/plugin from Codex (unrelated to MCP but same config file).
