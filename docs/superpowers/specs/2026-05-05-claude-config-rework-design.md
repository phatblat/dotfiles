# Claude Configuration Rework — Design Spec

## Goals

1. **Discoverability** — Know which command/skill/agent fires for what by reducing noise
2. **Token optimization** — Shrink config loaded per session (global + project CLAUDE.md)
3. **Eliminate overlap** — Remove duplicates between CLAUDE.md, skills, rules, and memory

## Approach: Curated Stack (Plan B)

Three-pronged cleanup: slim both CLAUDE.md files, move behavioral instructions into path-scoped rules, prune unused commands and skills, disable unused plugins.

---

## 1. Global CLAUDE.md (~3.2KB → ~1KB)

### Keep (always-loaded, session-wide)

- **Core Behavior** — Identity, language, copyright (3 lines)
- **Concision** — Response format preferences (4 lines)
- **Security Rules** — Slim version: no destructive commands without warning, secrets in env vars, never hardcode credentials, flag risks proactively. Drop the non-interactive flags list (move to rule).
- **Compact Preservation** — What to preserve during compaction (5 lines)
- **Session Completion** — Keep slim (5 lines). Not file-scoped, so doesn't fit the rules system.
- **`@RTK.md` reference** — Keep the include

### Move to rules

- **Toolchain** (`Python: uv/ruff/pytest`, `JS/TS: prettier/vitest/eslint`, `Rust: cargo`) → New rule `toolchain.md` scoped to `**/*.py`, `**/*.ts`, `**/*.tsx`, `**/*.rs`, `**/*.js`, `**/*.jsx`
- **Non-interactive flags list** → New rule `non-interactive.md` scoped to all files (or merge into existing bash-guard hook)

### Remove (redundant)

- **Anti-Hallucination Protocol** — Duplicated by `anti-hallucination` skill
- **Code Standards / Response Format** — Enforced by output style; overlaps with python/typescript rules
- **Confidence Levels** — Overlaps with `anti-hallucination` skill

---

## 2. Project CLAUDE.md (~14KB → ~5-6KB)

### Keep in CLAUDE.md (always-loaded for dotfiles sessions)

- **Repository Overview + Key Directories** — Slim to essential orientation
- **Shell Priority & Maintenance** — Slim (remove verbose per-shell details)
- **Code Search** — One line: "Use ast-grep (sg), not grep/ripgrep/sed"
- **Project Context** — 1-2 lines: primary language focus and use cases
- **Special Notes** — Tool installation priority, ast-grep, bat, no timeout/gtimeout
- **Communication Notes** — Move "push back with evidence" and "match surrounding code style" to global CLAUDE.md. Drop "address as phatblat" (derivable from git config).
- **MCP Tools: code-review-graph** — Keep but slim the tool table to essential entries

### Move to path-scoped rules

- **Managing Shell Functions** → New rule `shell-functions.md`
  - Paths: `.config/zsh/**`, `.config/fish/**`, `.config/nushell/**`, `.zshrc`, `.bashrc`, `docs/functions.md`
  - Content: Zsh autoload pattern (critical), per-shell file locations, always update functions.md
- **Git Workflow** → New rule `git-workflow.md`
  - Paths: `.gitconfig`, `.config/git/**`, `.gitignore`
  - Content: Conventional commits, branch naming, worktree conventions (dotfiles exception), branch tracking, GPG signing, no --no-verify, PR body format
- **Git Configuration** → Merge into `git-workflow.md` rule above

### Remove (derivable or stale)

- **Shell Function Categories** — Derivable from `docs/functions.md`
- **Development Tools & Versions** — Stale immediately; `mise ls` is authoritative
- **Just Recipes** — `just --list` is authoritative
- **Editor Configuration** — Derivable from `.editorconfig` and `.config/zed/settings.json`
- **When Hooks Fail** — Duplicate of global CLAUDE.md security rules
- **Development Workspace Organization** — Derivable from `ls ~/dev/`

---

## 3. New Rules

### Existing rules (keep as-is)

- `python.md` — Scoped to `**/*.py`, `pyproject.toml`, `uv.lock`
- `typescript.md` — Scoped to `**/*.ts`, `**/*.tsx`, `**/*.mts`, `tsconfig.json`, `package.json`

### New rules to create

#### `shell-functions.md`

Paths: `.config/zsh/**`, `.config/fish/**`, `.config/nushell/**`, `.zshrc`, `.bashrc`, `docs/functions.md`

Content:
- Zsh autoload pattern: file content IS the function body, no `function name() {}` wrapper
- Shebang: `#!/usr/bin/env zsh`
- Comment: `# name - Description`
- Per-shell file locations
- Always update `docs/functions.md` (alphabetical table, shell checkmarks)
- Test in target shell

#### `git-workflow.md`

Paths: `.gitconfig`, `.config/git/**`, `.gitignore`, `**/.git/**`

Content:
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:` (imperative mood, present tense)
- Branch naming: `ben/<topic>` or daily weekday names
- Worktree location: `~/.worktrees/<path-key>/<branch>` only
- Dotfiles exception: never use worktrees in dotfiles repo
- Branch tracking: `git push -u <remote> <branch>:<branch>` immediately after creation
- GPG signing enabled, never bypass hooks
- PR body: ticket refs above first heading

#### `rust.md`

Paths: `**/*.rs`, `Cargo.toml`, `Cargo.lock`

Content:
- Build/test/lint: `cargo check`, `cargo test`, `cargo clippy`
- Formatter: `cargo fmt`

Note: Python and TypeScript toolchain info is already in their respective rules. No separate `toolchain.md` needed.

---

## 4. Command Prune

### Keep (7 commands)

| Command | Path |
|---|---|
| `/daily-pr` | `commands/daily-pr.md` |
| `/git:commit` | `commands/git/commit.md` |
| `/git:cleanup` | `commands/git/cleanup.md` |
| `/git:push` | `commands/git/push.md` (dependency of git:commit) |
| `/git:status` | `commands/git/status.md` (dependency of git:commit) |
| `/git:rebase` | `commands/git/rebase.md` |
| `/retro` | `commands/retro.md` |
| `/dupe` | `commands/dupe.md` (58 bytes, no-op) |

### Archive (~43 commands)

Move to `~/.claude/commands/_archive/`. Preserves files for recovery without polluting the command list.

Affected top-level commands: `better-init`, `code-review`, `create-command`, `create-subagent`, `fix-build`, `git` (top-level), `init-workspace`, `linear-create`, `orchestrate`, `organize`, `organize-screenshots`, `plan` (top-level), `purge-worktrees`, `research`, `save-to-md`, `spec` (top-level), `validate-and-fix`

Affected directories: `agents-md/`, `analyze/`, `archive/`, `checkpoint/`, `config/`, `docs/`, `execute/`, `gh/`, `plan/` (except `linear.md`), `report/`, `research/`, `role/`, `spec/`

Remaining git commands to archive: `git/checkout.md`, `git/commit-single.md`, `git/ignore-init.md`

---

## 5. Skill & Agent Cleanup

### Delete auto-generated flat skills (~40 files)

Remove from `~/.claude/skills/`: `android-validator.md`, `awk-executor.md`, `cmake-executor.md`, `code-browser.md`, `cpp-validator.md`, `dart-validator.md`, `diagram-generator.md`, `ditto-docs-search.md`, `doc-extractor.md`, `docker-executor.md`, `document-processor.md`, `dotnet-validator.md`, `doxygen-validator.md`, `dql-validator.md`, `embedded-toolchain.md`, `format-converter.md`, `git-executor.md`, `go-validator.md`, `http-client.md`, `js-validator.md`, `linear-searcher.md`, `linux-system.md`, `macos-system.md`, `make-executor.md`, `markdown-validator.md`, `ml-executor.md`, `network-diagnostics.md`, `notion-searcher.md`, `python-validator.md`, `rerun-until-stable.md`, `rust-validator.md`, `shell-validator.md`, `slack-searcher.md`, `swift-validator.md`, `test-runner.md`, `vscode-executor.md`

### Delete duplicate project skills (~36 files)

Remove from `.claude/skills/`: same list as above (identical copies)

### Keep project skills (4 files)

- `.claude/skills/debug-issue.md`
- `.claude/skills/explore-codebase.md`
- `.claude/skills/refactor-safely.md`
- `.claude/skills/review-changes.md`

### Keep plugin-managed skill directories (10)

`anti-hallucination/`, `boris/`, `brainstorm/`, `code-patterns/`, `commit-message/`, `core-protocols/`, `git-worktrees/`, `research-protocol/`, `security-audit/`, `uv-workflow/`

### Keep all plugin-managed agents (~40)

No changes — these are managed by plugins and only load when relevant subagent types are requested.

---

## 6. Plugin Changes

### Disable (4)

- `code-simplifier@claude-plugins-official`
- `ralph-loop@claude-plugins-official`
- `wasteland@gastownhall-marketplace`
- `ruby-lsp@claude-plugins-official`

### Keep (18)

All remaining plugins including: superpowers, hookify, linear, code-review, claude-md-management, skill-creator, security-guidance, warp, claude-code-setup, and all LSPs (clangd, csharp, gopls, jdtls, kotlin, lua, rust-analyzer, swift, typescript).

---

## 7. Memory — No Changes

The 4 feedback memories are clean, relevant, and well-structured. No action needed.

---

## Implementation Order

1. Create new rules (additive, no risk)
2. Slim global CLAUDE.md
3. Slim project CLAUDE.md
4. Archive unused commands
5. Delete auto-generated skills
6. Disable plugins
7. Commit and test
