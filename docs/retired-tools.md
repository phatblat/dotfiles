# Retired Tools

Tools that were once installed/pinned in this repo and have since been removed. Kept as a
record so a future "why isn't X here anymore" question has an answer, and so a tool isn't
re-added out of habit without knowing it was deliberately dropped.

Each entry: package/tool name, where it was managed, when and why it was removed.

## npm:oh-my-claude-sisyphus

- **Managed via**: mise (`.config/mise/config.toml`, `npm:oh-my-claude-sisyphus`)
- **Removed**: 2026-09-22
- **Reason**: Unused — not referenced by any workflow, skill, or script in this repo aside
  from an optional, best-effort HUD probe (`hud/omc-hud.mjs`, which tries importing
  `oh-my-claude-sisyphus/dist/hud/index.js` behind an `existsSync` guard and silently skips
  it if absent). Confirmed via repo-wide search that no config, command, or doc depended on
  the pinned CLI itself.
- **Cleanup**: Removed the `[tools]` entry from `.config/mise/config.toml` and ran
  `mise uninstall npm:oh-my-claude-sisyphus --all` to remove the 3 installed versions
  (5.1.0, 5.3.0, 5.4.0) from `~/.local/share/mise/installs/`.
- **Note**: Not to be confused with `oh-my-claudecode` (a separate, unrelated Claude Code
  plugin/marketplace entry — see `docs/mcp-servers.md` and `docs/harness/plugins.md`), which
  is still referenced elsewhere in this repo and was not affected by this removal.

## npm:ccusage

- **Managed via**: mise (`.config/mise/config.toml`, `npm:ccusage`)
- **Removed**: 2026-09-22
- **Reason**: Retired by request. Unlike the other entries in this log, `ccusage` was an
  active dependency — wired into `just usage` and `just usage-board` in
  `.config/just/claude.just` — so both recipes were removed alongside the mise entry
  rather than left dangling. `just usage-web` (opens the usage page on claude.ai) was
  removed separately in a follow-up; there is no remaining `just` recipe for checking
  Claude usage.
- **Cleanup**: Removed the `[tools]` entry from `.config/mise/config.toml`, deleted the
  `usage` and `usage-board` recipes from `.config/just/claude.just`, and ran
  `mise uninstall npm:ccusage --all` to remove the 3 installed versions (20.0.20, 20.0.23,
  20.0.24) from `~/.local/share/mise/installs/`.
