# Harness Map

Per-harness CLI binary, config root, files worth reading, session store, and
known gotchas for `optimize-harness`. Session-store record schemas live in
`docs/agent-session-transcripts.md`; this file is the audit-focused
counterpart — where to look and what has already been investigated.

## claude

- CLI: `claude`. Config root: `~/.claude`.
- Files worth reading: `~/.claude/settings.json` (hooks, permissions,
  enabledPlugins), `~/.claude/hooks/scripts/`,
  `~/.claude/projects/*/settings.json` (project-level allowlists promotable
  to global), `~/.claude/logs/tool-failures.log`.
- Session store: `~/.claude/projects/*/*.jsonl` — see
  `docs/agent-session-transcripts.md#claude`.

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
  `~/.config/opencode/commands/`. Skills load natively from `~/.agents/skills/`.
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
- An OMP `logs/harness-guard.log` whose newest row predates the newest OMP
  session means the guard hook failed to load: on 2026-10-25, `af41d4e` had
  broken the parse of `hooks/pre/harness-guard.ts`. Check
  `bun build --no-bundle --target=bun ~/.omp/agent/hooks/pre/harness-guard.ts`
  first; the hk `ts-parse` step now catches this in `just lint`.

## antigravity

- CLI: `agy`. Config root: `~/.gemini` plus the generated adapter at
  `~/.agents/harness/adapters/antigravity`.
- Session store: `~/.gemini/antigravity-cli/history.jsonl` only — see
  `docs/agent-session-transcripts.md#antigravity`.
  `~/.gemini/antigravity-cli/conversations/*.pb` is protobuf with no
  published schema and is on the guard's protected-path list
  (`[protected_paths]` in `~/.config/ness/policy.toml`); transcript bodies there
  are permanently out of audit coverage.

## cursor

- CLI: `cursor-agent`. Config root: `~/.cursor` (blanket-gitignored, see
  `~/.gitignore:255`) plus the generated adapter at
  `~/.agents/harness/adapters/cursor`.
- Files worth reading: `.mdc` rules, generated plugin config, generated
  skill wrappers.
- Session store: `~/.cursor/projects/*/agent-transcripts/*/*.jsonl` — see
  `docs/agent-session-transcripts.md#cursor`. A handful of local transcripts
  (3 in a 30-day window); they carry no timestamps and no tool results, so
  error rates are unmeasurable. Expect a low-coverage report.

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

## crush

- CLI: `crush`. Config root: `~/.config/crush`.
- Files worth reading: `crushrc` (generated by `render_crush_config()`:
  `option global-context-path`, `option skill-path "$HOME/.agents/skills"`,
  attribution options, and the `hook add PreToolUse` guard),
  `shared-harness.md` (`render_crush_context()`), and
  `hooks/harness-guard.sh` (`render_crush_guard()`; fails closed when ness is
  missing).
- Session store: none. Transcripts live in `crush.db` (default
  `~/.local/share/crush`; `CRUSH_GLOBAL_DATA`, then `XDG_DATA_HOME`), whose
  schema is not a public API, so the scanner never parses it. On 2026-10-25
  the data directory did not exist.

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
  layers `sudo *` → `deny` over it, plus the independent `ness` pre-tool hook. Judge the
  effective policy, not the mode name. The `rm *` rule is emitted as `prompt`
  (omp accepts only `allow|deny|prompt` and silently drops `ask`; fixed 2026-10-16; the
  baseline now lives in `[approval]` of `~/.config/ness/policy.toml`, rendered by
  `scripts/harness_policy.py`), and named profiles load the same ness hook through the
  `hooks`/`extensions` links `generate-omp-profiles.sh` maintains.
- **A grok scan of 0 files with `files_skipped_since: 1` is genuine inactivity**, not a scanner
  gap: the one session dir was last written 56 days before the audit. The scanner globs session
  directories and reads `chat_history.jsonl`/`events.jsonl` by name. Widen `--since` instead.
- **`just audit-ignored-config` lives in `.config/just/agents.just`**, imported by
  `~/justfile`. Grepping `~/justfile` alone reports it missing.
- **Claude's five `PASEO_TERMINAL_ID` hooks are live**, not stale: Paseo is installed at
  `/Applications/Agents/Paseo.app` with a running daemon under `~/.paseo/`.
- **`hub` p95 of 600,003ms, `ask` p95 of ~84 minutes, `wait` p95 of 361s, and `eval` p95 of 66s are
  blocking-wait ceilings, human think time, or long-running work, not tool latency. Exclude blocking
  or long-running tools from latency findings.
- **`context-mode` was removed 2026-08-25** (`docs/mcp-servers.md`, History) and has zero
  hits across all 7 MCP config files, `claude plugin list`, and the marketplace list. Do
  not re-flag `ctx7` (Context7's docs CLI) as a context-mode remnant — different tool,
  similar name.
- **Codex `~/.codex/auth.json` is not tracked in git** and carries no OAuth tokens into a
  commit. A prior audit pass flagged this as Critical; `git ls-files` shows it untracked
  and `git check-ignore -v` resolves it to `.gitignore:112:.codex/*`. Verify with both
  commands before flagging a credential file as tracked — do not infer tracked status
  from the file's existence or its content alone.
- **OMP's raw bash error rate is not a config defect.** Of the errors behind the
  2026-09-07 finding ("6.2% error rate needs a config fix"), the only config-caused share
  was the guard false positives fixed above (157 denials). The rest is agent behavior:
  88 `git` pathspec misses, 117 non-zero exits with no output (e.g. `grep` exit 1), 152
  `read` path-not-found. Re-measure the guard-caused share after the ness patch before
  treating the remainder as a harness problem.
- **Cursor's `approvalMode: allowlist` with 22 read-only allow rules plus 6 deny rules
  (`4dd6625`) is deliberate**, not overly restrictive — it is a light annotation tool, and
  no wider access was requested. The `just`/`make` allows are intentional.

- **2026-10-23 ness false-positive denials fixed by the four `fix(policy)` commits.** Replay counts:
  rm 56/78, `sk-` 60/77, wiper words 7/12. The remaining denials target non-temp paths, include real
  secrets, or put the command in command position.
- **2026-10-23 "ness is not installed" rows after 2026-10-10 were a missing session cwd**, fixed in the
  OMP hook (`fix(omp)`). The 2026-10-04 rows predate the atomic install `43f9c80`.
- **2026-10-23 the 6 "policy … is not applied" rows on 2026-10-21T03Z** were the one-time bootstrap
  before the first `ness policy apply`.
- **2026-10-23 OMP `bashInterceptor` redirects (210/1,080 bash errors), edit `stale_anchor` (75/1,231),
  and read/grep/glob `not_found` are agent behavior, not config.**
- **2026-10-23 Claude hook cost and cache misses** came from a window (2026-08-11→2026-10-12, 5 files,
  4 sessions) that predates `2f1ad49`, `9c7bd68`, `f50baf2`, and `449ae20`. Re-measure only after new
  Claude sessions.
- **2026-10-23 Codex (one October rollout, 2026-10-10) and Pi (0 files in the window) are genuinely
  inactive.**
- **2026-10-23 aborted turns are OMP `session_exit` signals and OpenCode message errors, never Claude.**
  The scanner now groups them by harness.
- **2026-10-25 OMP edit `stale_anchor` over the full 30-day window is 295/4,026 (7.3%)**, against
  75/1,231 (6.1%) on the capped 2026-10-23 scan: the same rate, still agent behavior.
- **2026-10-25 guard denials logged after the 2026-10-23 fixes** (2026-10-20→10-24) are
  control-plane writes, `Dangerous command pattern` (10), and one 10-second burst of 8
  `policy.toml: TOML parse error` rows at 2026-10-24T21:27Z right after a policy apply;
  `ness policy active` reports the policy verified.
- **2026-10-25 `~/.claude/settings.local.json` is the dotfiles project's local settings** (repo
  root is `~`), so its 7 LSP `false` overrides apply only to Claude sessions in `~`;
  `docs/harness/plugins.md` correctly reports the user-level state.
- **2026-10-25 `~/.cursor/plugins/local/shared-agent-harness/` is the `just cursor-plugin-install`
  rsync copy** of the generated adapter; `scripts/`, `rules/`, and `mcp.json` are excluded on purpose.
- **2026-10-25 `~/.gemini/config/mcp_config.json` is written by the Data Agent Kit install** (its
  servers run `googlecloudtools.datacloud-*/mcp_servers/cli/mcp_proxy_bundle.js`). Dismiss it in
  `audit-ignored-config`; never track it.
- **2026-10-25 the 20 skills flagged in Codex but advertised in OMP/Claude stay advertised** (user
  decision). Five have measured OMP model reads (resolve-review-feedback 87, git-worktree 14,
  backlog-batch-delivery 8, git-push 7, gha-log-reader 6), and `00c94b9` already hid the
  explicit-only set.
