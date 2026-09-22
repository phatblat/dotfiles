# Harness Map

Per-harness CLI binary, config root, files worth reading, session store, and
known gotchas for `optimize-harness`. Session-store record schemas live in
`docs/agent-session-transcripts.md`; this file is the audit-focused
counterpart — where to look and what has already been investigated.

## claude

- CLI: `claude`. Config root: `~/.claude`.
- Files worth reading: `~/.claude/settings.json` (hooks, permissions,
  enabledPlugins), `~/.claude/hooks/scripts/`, `~/.claude/agent-flow/`,
  `~/.claude/projects/*/settings.json` (project-level allowlists promotable
  to global), `~/.claude/logs/tool-failures.log`.
- Session store: `~/.claude/projects/*/*.jsonl` — see
  `docs/agent-session-transcripts.md#claude`.

### Known-good hook exception (investigated — do not re-flag)

`agent-flow-guard.sh` is registered on all 9 Claude Code hook events
(`Notification`, `PostToolUse`, `PostToolUseFailure`, `PreToolUse`,
`SessionEnd`, `SessionStart`, `Stop`, `SubagentStart`, `SubagentStop`). This
is **not** redundant duplication — it is required by
`DittoAgentOrchestrator`'s visualizer contract
(`~/dev/agents/claude/DittoAgentOrchestrator/src/ditto_agent/orchestrator/hooks.py`,
`HOOK_EVENTS` tuple and docstring: "configure `~/.claude/settings.json` for
all 9 Claude Code hook events"). Dropping any event creates a gap in the
live trace view (e.g. no `SubagentStop` means the visualizer never sees a
subagent's timeline close). The guard script's `find | grep -q` pre-check
(dotfiles commits `adf7d`, `4bc1`) already skips spawning `mise exec bun`
entirely when no live Agent Flow session is listening, so the registration
breadth does not imply hot-path cost on every firing.

**Rule before flagging any hook as redundant in general**: check
`git log --oneline -- <hook script path>` in the dotfiles repo for prior
`optimize:`/`fix:` commits — a hook that looks like duplicated overhead may
already be a deliberately tuned guard around an external tool's fixed event
contract.

### Permission command families investigated

- Git operations: `status`, `branch`, `log`, `diff`, `fetch`, `checkout`,
  `push`, `commit`, `pull`, `rev-list`, `ls-remote`, `rev-parse`, `show`,
  `remote`, `symbolic-ref`, `merge`, `rebase`, `stash`, `tag`.
- GitHub CLI: `pr` (list/create/view/merge/edit), `api`, `run`
  (list/view), `issue`.
- Build tools: `just`, `make`, `cargo`, `go`, `npm`, `pnpm`, `yarn`, `pip`,
  `poetry`.
- Search/nav: `find`, `ls`, `wc`, `grep`, `rg`, `sg`, `fd`, `tree`, `file`,
  `stat`, `head`, `tail`.
- Utilities: `date`, `python3`, `jq`, `yq`, `sed`, `awk`, `sort`, `uniq`,
  `tr`, `cut`, `basename`, `dirname`.
- Mise: `ls`, `search`, `use`, `install`, `current`.

Cross-reference against `~/.claude/logs/tool-failures.log` for patterns —
commands that failed due to permission denial or indicate frequent use.

## codex

- CLI: `codex`. Config root: `~/.codex`.
- Files worth reading: `~/.codex/config.toml`, `~/.codex/hooks.json`,
  `~/.codex/hooks/scripts/`, `.agents/skills/*/agents/openai.yaml`
  (`policy.allow_implicit_invocation`, `dependencies.tools`).
- Session store: `~/.codex/sessions/**/rollout-*.jsonl` — see
  `docs/agent-session-transcripts.md#codex`.
- `CODEX_HOME` env override confirmed present in `codex --help`.

## opencode

- CLI: `opencode`. Config root: `~/.config/opencode`.
- Files worth reading: `opencode.jsonc` config, plugin hooks,
  `~/.config/opencode/skills/`, `~/.config/opencode/commands/`.
- Session store: SQLite `~/.local/share/opencode/opencode.db` — see
  `docs/agent-session-transcripts.md#opencode`. Local message/part volume is
  characteristically tiny relative to session count; treat that as low
  coverage, not as opencode features being unused.

## pi

- CLI: `pi`. Config root: `~/.pi/agent`.
- Files worth reading: effective Pi settings (user agent directory plus a
  trusted project `.pi/settings.json`), local skill/extension adapters.
- Session store: `~/.pi/agent/sessions/*.jsonl` — see
  `docs/agent-session-transcripts.md#pi`.
- `PI_CODING_AGENT_SESSION_DIR` then `PI_CODING_AGENT_DIR` env overrides
  confirmed present.

## omp

- CLI: `omp`. Config root: `~/.omp/agent`.
- Files worth reading: `~/.omp/agent/config.yml` (`tools.approval`),
  `~/.omp/agent/agents/` (generated agent wrappers), `~/.omp/agent/mcp.json`.
- Session store: `~/.omp/agent/sessions/**/*.jsonl` (recursive — nested
  subagent transcripts sit beside the parent at variable depth) — see
  `docs/agent-session-transcripts.md#omp`.
- `OMP_PROFILE`, then `PI_CODING_AGENT_DIR`, then `PI_CONFIG_DIR`, then
  `XDG_DATA_HOME` env overrides confirmed present, in that precedence
  order.

## antigravity

- CLI: `agy`. Config root: `~/.gemini` plus the generated adapter at
  `~/.agents/harness/adapters/antigravity`.
- Session store: `~/.gemini/antigravity-cli/history.jsonl` only — see
  `docs/agent-session-transcripts.md#antigravity`.
  `~/.gemini/antigravity-cli/conversations/*.pb` is protobuf with no
  published schema and is on the guard's protected-path list
  (`crates/ness/src/policy.rs`'s `PROTECTED_PATHS`); transcript bodies there
  are permanently out of audit coverage.

## cursor

- CLI: `cursor-agent`. Config root: `~/.cursor` (blanket-gitignored, see
  `~/.gitignore:255`) plus the generated adapter at
  `~/.agents/harness/adapters/cursor`.
- Files worth reading: `.mdc` rules, generated plugin config, generated
  skill wrappers.
- Session store: `~/.cursor/projects/*/agent-transcripts/*/*.jsonl` — see
  `docs/agent-session-transcripts.md#cursor`. Single local transcript file
  observed; expect a low-coverage report.

## grok

- CLI: `grok`. Config root: `~/.grok`.
- Files worth reading: `~/.grok/config.toml` (`[mcp_servers.*]` — natively
  declared servers only). `[compat.claude]`/`[compat.cursor] mcps = true`
  in `config.toml` means grok also inherits MCP servers from
  `~/.claude.json`/`~/.cursor/mcp.json` plus plugin bridges; `grok mcp
  list --json` shows only the native list (often empty), while `grok mcp
  doctor` additionally resolves the compat-inherited servers — use
  `doctor`, not `list` or a bare `config.toml` grep, to see grok's
  effective MCP surface (2026-09-07 optimize-harness audit finding).
- Session store: `~/.grok/sessions/<url-encoded-cwd>/<id>/
  {chat_history,events,updates}.jsonl` — see
  `docs/agent-session-transcripts.md#grok`. `events.jsonl` carries the only
  friction signal (MCP server lifecycle); `chat_history.jsonl` has no tool
  events. `sessions/session_search.sqlite` is an FTS index over the same
  transcript text and is never read.

## Investigated and closed (do not re-flag)

Each entry below was checked against primary evidence on 2026-09-22. Re-open one only
with new measurements, not with a fresh reading of the same config.

- **Guard timeout is not a source of bash errors.** The 2026-09-07 audit added verdict
  logging to `~/.omp/agent/logs/harness-guard.log` to separate "ness denied or timed out"
  from "the command failed". Answer, over 5,711 verdicts from 2026-09-07 to 2026-09-22:
  p50 13ms, p95 233ms, p99 1,927ms, max 4,870ms, zero verdicts at the 5,000ms
  `GUARD_TIMEOUT_MS`, and zero fail-closed rows. Do not recommend raising the timeout
  without a log row that actually hits it.
- **Triaging a guard denial needs a call-ID join, not a timestamp window.** The guard log
  records the reason but not the command. Join each errored `toolResult` to its
  `toolCall` by `toolCallId` inside one session file; nearest-timestamp correlation
  mislabels roughly 15% of denials.
- **OMP agent wrappers in `~/.omp/agent/agents/` are intentional pointers**, not stubs.
  Each carries name/description frontmatter and directs the agent to read the full
  profile at `~/.agents/harness/agents/<name>.toml`. Generated by `render_omp_agent()`.
- **OMP `tools.approvalMode: yolo` is not an ungated configuration.** `~/.omp/agent/config.yml`
  layers `sudo *` → `deny` and `rm *` → `ask` over it, plus the independent `ness`
  pre-tool hook. Judge the effective policy, not the mode name.
- **`just audit-ignored-config` lives in `.config/just/agents.just`**, imported by
  `~/justfile`. Grepping `~/justfile` alone reports it missing.
- **Claude's five `PASEO_TERMINAL_ID` hooks are live**, not stale: Paseo is installed at
  `/Applications/Agents/Paseo.app` with a running daemon under `~/.paseo/`.
- **`hub` p95 of 600,003ms and `ask` p95 of ~84 minutes are blocking-wait ceilings and
  human think time**, not tool latency. Exclude blocking-wait tools from latency findings.
- **`context-mode` was removed 2026-08-25** (`docs/mcp-servers.md`, History) and has zero
  hits across all 7 MCP config files, `claude plugin list`, and the marketplace list. Do
  not re-flag `ctx7` (Context7's docs CLI) as a context-mode remnant — different tool,
  similar name.
