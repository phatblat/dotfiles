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
- Usage data: `rtk gain --history` is the Claude command-frequency and
  token-savings source (heavy-hitter commands, unproxied CLI tools,
  permission-prompt tax) — a distinct signal from the session scanner's
  transcript-derived usage/friction data, not a replacement for it.
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
- RTK: `gain`, `discover`, `--version`.

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
  (`~/.agents/harness/hooks/safety.py:71`); transcript bodies there are
  permanently out of audit coverage.

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
- Files worth reading: `~/.grok/config.toml` (`[mcp_servers.*]`).
- Session store: `~/.grok/sessions/<url-encoded-cwd>/<id>/
  {chat_history,events,updates}.jsonl` — see
  `docs/agent-session-transcripts.md#grok`. `events.jsonl` carries the only
  friction signal (MCP server lifecycle); `chat_history.jsonl` has no tool
  events. `sessions/session_search.sqlite` is an FTS index over the same
  transcript text and is never read.
