# Harness Signals

Where each harness records experience, which hook events can trigger the
Record stage, and which native learning features exist. These facts drift
with every release. Re-verify a row against the harness's primary docs (the
`find-docs` skill) before naming it in a flywheel doc, and write
`unverified` in the doc when you cannot.

## Repo-root markers

| Marker | Harness | Slug |
|---|---|---|
| `CLAUDE.md`, `.claude/` | Claude Code | `claude` |
| `.codex/` | Codex | `codex` |
| `.cursor/`, `.cursorrules` | Cursor | `cursor` |
| `GEMINI.md`, `.gemini/` | Gemini CLI / Antigravity | `antigravity` |
| `opencode.json`, `.opencode/` | OpenCode | `opencode` |
| `.pi/` | Pi | `pi` |
| `.omp/` | Oh My Pi | `omp` |
| `.grok/` | Grok | `grok` |
| `crush.json`, `.crush.json` | Crush (unverified) | `crush` |
| `.github/copilot-instructions.md` | GitHub Copilot | `-` |
| `AGENTS.md`, `.agents/` | Shared instructions and skills, read by several harnesses; not a harness on its own | `-` |

Markers are hints. When they are ambiguous, ask which harnesses the team
actually uses.

## Session stores (user level, defaults)

From phatblat dotfiles `scripts/harness_paths.py` `SESSION_STORES` and
`docs/agent-session-transcripts.md`, as of 2026-10-25.

| Harness | Slug | Default store | Kind | Override | Verified |
|---|---|---|---|---|---|
| Claude Code | `claude` | `~/.claude/projects/**/*.jsonl` | jsonl | `CLAUDE_CONFIG_DIR` | no |
| Codex | `codex` | `~/.codex/sessions/**/rollout-*.jsonl` | jsonl | `CODEX_HOME` | yes |
| OpenCode | `opencode` | `~/.local/share/opencode/opencode.db` | sqlite | `XDG_DATA_HOME` | no |
| Pi | `pi` | `~/.pi/agent/sessions/**/*.jsonl` | jsonl | `PI_CODING_AGENT_SESSION_DIR`, `PI_CODING_AGENT_DIR` | yes |
| Oh My Pi | `omp` | `~/.omp/agent/sessions/**/*.jsonl`; named profile: `~/.omp/profiles/<profile>/agent/sessions` | jsonl | `OMP_PROFILE` | yes |
| Antigravity | `antigravity` | `~/.gemini/antigravity-cli/history.jsonl`; conversation bodies are protobuf, outside coverage | jsonl | none known | no |
| Cursor | `cursor` | `~/.cursor/projects/*/agent-transcripts/*/*.jsonl` | jsonl | none known | no |
| Grok | `grok` | `~/.grok/sessions/<url-encoded-cwd>/<id>/{chat_history,events}.jsonl` | jsonl | none known | no |
| Crush | `crush` | `~/.local/share/crush/crush.db`; schema is not a public API, so it is not scanned | sqlite | `CRUSH_GLOBAL_DATA`, `XDG_DATA_HOME` | no |

Never read these, even when they sit inside a session store:

- credential stores (`.claude/.credentials.json`, `.codex/auth.json`,
  `.omp/agent/agent.db`, `.omp/agent/secrets.yml`, `.pi/agent/auth.json`,
  `.grok/auth.json`)
- Claude `history.jsonl` (raw prompt text)
- Antigravity `conversations/*.pb`

## Hook events for the Record stage

| Harness | Hook config | Events seen configured (not exhaustive) |
|---|---|---|
| Claude Code | `.claude/settings.json` `hooks` (project), `~/.claude/settings.json` (user) | `SessionEnd`, `Stop`, `StopFailure`, `PreCompact`, `PostToolUseFailure`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Notification` |
| Codex | `.codex/hooks.json` | `Stop`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PermissionRequest` |
| Oh My Pi | `<cwd>/.omp/extensions/`, `~/.omp/agent/extensions/`, `~/.omp/agent/hooks/` (auto-discovered TS/JS extensions and hooks) | see the `omp-hooks` skill |
| Pi / OpenCode | `~/.pi/agent/extensions/`, `~/.config/opencode/plugins/` (auto-discovered TS/JS extensions and plugins) | see primary docs |
| Crush | `~/.config/crush/crushrc` (`hook add` lines) | see primary docs |
| Others | check primary docs | unknown |

On phatblat dotfiles, `.agents/harness/hooks/contract.json` normalizes
events across harnesses as `session_start`, `user_prompt`, `tool_call`,
`tool_result`, `failure`, and `compaction`.

## Native learning features

| Harness | Feature | Stage | Status |
|---|---|---|---|
| Oh My Pi | Long-term memory (`retain`, `recall`, `reflect`) | Record, Apply | observed 2026-10-25 |
| Oh My Pi | `learn` (durable lessons, optionally minting a managed skill) | Apply | observed 2026-10-25 |
| Oh My Pi | Managed skills in `~/.omp/agent/managed-skills` | Apply | observed 2026-10-25 |
| Oh My Pi | Continual Harness state (`harness_list`, `harness_mutate`; kinds `prompt`, `memory`, `skill`, `subagent`) | Apply, Prune | observed 2026-10-25 |
| Claude Code | `CLAUDE.md` instruction files | Enable, Apply | loaded each session |
| Any other | Memory or self-learning features | — | verify in primary docs before naming |

## phatblat dotfiles accelerators

Use these only when they are present on the machine:

| Tool | Stage | Use |
|---|---|---|
| `~/scripts/harness-sessions.py <slugs> --since <N> --json` | Record, Learn | `$HOME`-scoped coverage, usage, friction, and hook cost across user-level stores (`<slugs>` from the `Slug` column above), aggregate-only |
| `optimize-harness` skill | Learn → Apply | Prioritized, evidence-cited harness findings |
| `retro` skill | Apply | Targeted config fixes from friction points |
| `harness-research` skill | Enable | Re-verify capability facts after a release |
| `just harness-probe`, `docs/harness/drift.jsonl` | Tune | A harness version change triggers a replay and a register review |
