# Claude Configuration Rework — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce token cost and improve discoverability of Claude Code configuration by slimming CLAUDE.md files, creating path-scoped rules, pruning unused commands/skills, and disabling unused plugins.

**Architecture:** Additive changes first (new rules), then reductive changes (slim CLAUDE.md, archive commands, delete skills, disable plugins). Each task is independently committable and verifiable.

**Tech Stack:** Claude Code config files (Markdown, JSON), shell (zsh)

---

## Task 1: Create shell-functions rule

**Files:**
- Create: `~/.claude/rules/shell-functions.md`

- [ ] **Step 1: Create the rule file**

```markdown
---
paths:
  - ".config/zsh/**"
  - ".config/fish/**"
  - ".config/nushell/**"
  - ".zshrc"
  - ".bashrc"
  - "docs/functions.md"
---

# Shell Function Conventions

## Shell Priority

1. **Zsh (Primary)** — Functions in `~/.config/zsh/functions/*`
2. **Fish (Secondary)** — Functions in `~/.config/fish/functions/*.fish`
3. **Nushell (Active)** — Functions in `~/.config/nushell/autoload/*.nu`
4. **Bash (Minimal)** — Define in `~/.bashrc`

## Zsh Autoload Pattern (CRITICAL)

- Create standalone files in `~/.config/zsh/functions/` — never define in `.zshrc`
- File content IS the function body directly — NOT wrapped in `function name() { }`
- Start with `#!/usr/bin/env zsh` shebang
- Add comment: `# function_name - Description`
- No execute permissions needed

Example:
```zsh
#!/usr/bin/env zsh

# aa - Add all modified tracked files to git staging area
git add --update "$@"
```

## Required Bookkeeping

After any function change, ALWAYS update `~/docs/functions.md`:
- Add/remove/update the row in the alphabetically-sorted table
- Update checkmarks for which shells implement it (nu, fish, zsh, bash)
- Update Summary statistics if shell counts change

Test the function in the target shell.
```

- [ ] **Step 2: Verify the rule loads**

Run: `cat ~/.claude/rules/shell-functions.md | head -8`
Expected: YAML frontmatter with paths array

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/rules/shell-functions.md
git commit -m "feat(claude): add shell-functions rule for path-scoped shell config guidance"
```

---

## Task 2: Create git-workflow rule

**Files:**
- Create: `~/.claude/rules/git-workflow.md`

- [ ] **Step 1: Create the rule file**

```markdown
---
paths:
  - ".gitconfig"
  - ".config/git/**"
  - ".gitignore"
---

# Git Workflow Conventions

## Commits

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:` (imperative mood, present tense)
- GPG signing enabled globally
- Never bypass hooks with `--no-verify`

## Branches

- Feature branches: `ben/<topic>` or daily weekday names
- Every new branch MUST have remote tracking set up immediately after creation:
  ```bash
  git push -u <remote> <branch>:<branch>
  ```
- Verify with `git branch -vv`. Never let tracking point to the source branch.
- `main` is protected — cannot push directly

## Worktrees

- Location: `~/.worktrees/<path-key>/<branch>` ONLY
- `<path-key>` = repo root relative to `~` with `/` replaced by `-`
- **Dotfiles exception:** The dotfiles repo (rooted at `~`) must NOT use worktrees
- After merging/closing a PR: `git worktree remove <worktree-path>`
- Never force push to main/master

## PRs

- PR body: ticket references (e.g., `Resolves DEVX-123`) above the first heading

## Git Config Structure

- Global: `~/.gitconfig` (tracked)
- Local overrides: `~/.config/git/config` (not tracked, machine-specific email)
- Rerere enabled
```

- [ ] **Step 2: Verify the rule loads**

Run: `cat ~/.claude/rules/git-workflow.md | head -7`
Expected: YAML frontmatter with paths array

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/rules/git-workflow.md
git commit -m "feat(claude): add git-workflow rule for path-scoped git conventions"
```

---

## Task 3: Create rust rule

**Files:**
- Create: `~/.claude/rules/rust.md`

- [ ] **Step 1: Create the rule file**

```markdown
---
paths:
  - "**/*.rs"
  - "Cargo.toml"
  - "Cargo.lock"
---

# Rust Conventions

## Tooling
- Build/check: `cargo check`
- Tests: `cargo test`
- Linter: `cargo clippy`
- Formatter: `cargo fmt`

## Validation Command
After writing Rust code, always suggest: `cargo check && cargo test`
```

- [ ] **Step 2: Commit**

```bash
git add ~/.claude/rules/rust.md
git commit -m "feat(claude): add rust rule for path-scoped Rust conventions"
```

---

## Task 4: Slim global CLAUDE.md

**Files:**
- Modify: `~/.claude/CLAUDE.md`

- [ ] **Step 1: Replace the entire file with the slimmed version**

```markdown
# Global Claude Code Instructions

## Core Behavior

1. Always respond in the user's language (code comments stay in English)
2. Professional, direct, practical, skeptical tone
3. Copyright: Ben Chatelain. Apache 2.0

## Collaboration

- Push back with evidence — we're both fallible
- Match surrounding code style over style guides
- Only change code directly related to current task
- Prefer simple, maintainable solutions

@RTK.md

## Concision

```
Simple question → Short answer
Code request → Code first, explanation after
Complex topic → Headers, max 3 levels
Uncertainty → State immediately
```

## Security

- No destructive commands without explicit warning
- Secrets → environment variables, `.env` gitignored
- Never hardcode credentials
- Flag security risks proactively
- Warn before: rm -rf, DROP, force push, chmod 777

## Session Completion

- Run quality gates if code changed (tests, linters, builds)
- Push to remote before stopping — work is NOT complete until `git push` succeeds
- File issues for remaining work

## Compact Preservation

When context is compacted, ALWAYS preserve:

- List of modified files with paths
- Current git branch and uncommitted changes
- Pending tasks and TODO items
- Test results and failures
- Key architectural decisions made during session
```

- [ ] **Step 2: Verify file size reduction**

Run: `wc -c ~/.claude/CLAUDE.md`
Expected: ~900-1100 bytes (down from 3199)

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/CLAUDE.md
git commit -m "refactor(claude): slim global CLAUDE.md from 3.2KB to ~1KB"
```

---

## Task 5: Slim project CLAUDE.md

**Files:**
- Modify: `~/CLAUDE.md`

- [ ] **Step 1: Replace the entire file with the slimmed version**

```markdown
# CLAUDE.md

Dotfiles repository — cross-machine config sync. Home directory (`~`) is the git repo root.

## Key Directories

- `.config/` — Shell configs (zsh, fish, nushell), tool configs (zed, mise, home-manager)
- `bin/` — Custom utility scripts
- `dev/` — Development workspace organized by language/framework/org
- `docs/functions.md` — Complete inventory of shell functions/aliases

## Shell Architecture

1. **Zsh (Primary)** — `~/.zshrc`, functions in `~/.config/zsh/functions/*`
2. **Fish (Secondary)** — `~/.config/fish/config.fish`
3. **Nushell (Active)** — `~/.config/nushell/config.nu`
4. **Bash (Minimal)** — `~/.bashrc`

Shell function conventions are in the `shell-functions` rule (loads when editing shell config files).

## Project Context

Primarily shell scripting (Zsh), with Go, Ruby, Python, Swift, and other languages. Git workflow conventions are in the `git-workflow` rule.

## Code Search

Use **ast-grep** (`sg`) for code search, not grep/ripgrep/sed.

## Special Notes

- **bat** replaces cat in Zsh (syntax highlighting, git integration)
- **timeout/gtimeout** not installed
- **Tool installation priority:**
  1. `mise search`/`mise use` for mise-managed tools
  2. `nix profile install nixpkgs#<package>` for Nix packages
  3. `brew search`/`brew install` as fallback
- Tool versions: run `mise ls` (never hardcode versions — they go stale)
- Just recipes: run `just --list`

## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. Use code-review-graph MCP tools BEFORE Grep/Glob/Read to explore the codebase.** The graph gives structural context (callers, dependents, test coverage) that file scanning cannot.

- `detect_changes` — risk-scored change analysis
- `get_review_context` — token-efficient source snippets
- `get_impact_radius` / `get_affected_flows` — blast radius and execution paths
- `query_graph` — trace callers, callees, imports, tests
- `semantic_search_nodes` — find functions/classes by keyword

Fall back to Grep/Glob/Read only when the graph doesn't cover what you need.
```

- [ ] **Step 2: Verify file size reduction**

Run: `wc -c ~/CLAUDE.md`
Expected: ~1800-2200 bytes (down from 14227)

- [ ] **Step 3: Commit**

```bash
git add ~/CLAUDE.md
git commit -m "refactor(claude): slim project CLAUDE.md from 14KB to ~2KB"
```

---

## Task 6: Archive unused commands

**Files:**
- Move: ~43 command files/directories to `~/.claude/commands/_archive/`

- [ ] **Step 1: Create archive directory**

```bash
mkdir -p ~/.claude/commands/_archive/git
mkdir -p ~/.claude/commands/_archive/plan
```

- [ ] **Step 2: Archive top-level command files**

```bash
cd ~/.claude/commands
for f in better-init.md code-review.md create-command.md create-subagent.md \
         fix-build.md git.md init-workspace.md linear-create.md orchestrate.md \
         organize.md organize-screenshots.md plan.md purge-worktrees.md \
         research.md save-to-md.md spec.md validate-and-fix.md; do
  [ -f "$f" ] && mv -f "$f" _archive/
done
```

- [ ] **Step 3: Archive command directories**

```bash
cd ~/.claude/commands
for d in agents-md analyze archive checkpoint config docs execute gh report research role spec; do
  [ -d "$d" ] && mv -f "$d" _archive/
done
```

- [ ] **Step 4: Archive extra git subcommands**

```bash
cd ~/.claude/commands
for f in git/checkout.md git/commit-single.md git/ignore-init.md; do
  [ -f "$f" ] && mv -f "$f" _archive/git/
done
```

- [ ] **Step 5: Move plan/linear.md out before archiving plan directory**

The plan directory was already archived in step 3. Extract linear.md back:

```bash
mkdir -p ~/.claude/commands/plan
mv -f ~/.claude/commands/_archive/plan/linear.md ~/.claude/commands/plan/
```

- [ ] **Step 6: Verify kept commands**

```bash
find ~/.claude/commands -name "*.md" -not -path "*/_archive/*" | sort
```

Expected output:
```
~/.claude/commands/daily-pr.md
~/.claude/commands/dupe.md
~/.claude/commands/git/cleanup.md
~/.claude/commands/git/commit.md
~/.claude/commands/git/push.md
~/.claude/commands/git/rebase.md
~/.claude/commands/git/status.md
~/.claude/commands/plan/linear.md
~/.claude/commands/retro.md
```

- [ ] **Step 7: Commit**

```bash
git add ~/.claude/commands/
git commit -m "chore(claude): archive 43 unused commands to _archive/"
```

---

## Task 7: Delete auto-generated skills (global)

**Files:**
- Delete: ~40 files from `~/.claude/skills/`

- [ ] **Step 1: Delete the flat auto-generated skill files**

```bash
cd ~/.claude/skills
rm -f android-validator.md awk-executor.md cmake-executor.md code-browser.md \
     cpp-validator.md dart-validator.md diagram-generator.md ditto-docs-search.md \
     doc-extractor.md docker-executor.md document-processor.md dotnet-validator.md \
     doxygen-validator.md dql-validator.md embedded-toolchain.md format-converter.md \
     git-executor.md go-validator.md http-client.md js-validator.md \
     linear-searcher.md linux-system.md macos-system.md make-executor.md \
     markdown-validator.md ml-executor.md network-diagnostics.md notion-searcher.md \
     python-validator.md rerun-until-stable.md rust-validator.md shell-validator.md \
     slack-searcher.md swift-validator.md test-runner.md vscode-executor.md
```

- [ ] **Step 2: Verify only plugin directories remain**

```bash
ls ~/.claude/skills/
```

Expected: Only directories (anti-hallucination/, boris/, brainstorm/, etc.) plus debug-issue.md, explore-codebase.md, refactor-safely.md, review-changes.md if they exist here.

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/skills/
git commit -m "chore(claude): delete 36 auto-generated global skill files"
```

---

## Task 8: Delete duplicate project skills

**Files:**
- Delete: ~36 files from `.claude/skills/`

- [ ] **Step 1: Delete the duplicate project skill files**

```bash
cd .claude/skills
rm -f android-validator.md awk-executor.md cmake-executor.md code-browser.md \
     cpp-validator.md dart-validator.md diagram-generator.md ditto-docs-search.md \
     doc-extractor.md docker-executor.md document-processor.md dotnet-validator.md \
     doxygen-validator.md dql-validator.md embedded-toolchain.md format-converter.md \
     git-executor.md go-validator.md http-client.md js-validator.md \
     linear-searcher.md linux-system.md macos-system.md make-executor.md \
     markdown-validator.md ml-executor.md network-diagnostics.md notion-searcher.md \
     python-validator.md rerun-until-stable.md rust-validator.md shell-validator.md \
     slack-searcher.md swift-validator.md test-runner.md vscode-executor.md
```

- [ ] **Step 2: Verify kept project skills**

```bash
ls .claude/skills/
```

Expected: `debug-issue.md`, `explore-codebase.md`, `refactor-safely.md`, `review-changes.md`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/
git commit -m "chore(claude): delete 36 duplicate project skill files"
```

---

## Task 9: Disable plugins

**Files:**
- Modify: `~/.claude/settings.json`

- [ ] **Step 1: Disable 4 plugins in settings.json**

Set these to `false` in the `enabledPlugins` object:
- `"code-simplifier@claude-plugins-official": false`
- `"ralph-loop@claude-plugins-official": false`
- `"wasteland@gastownhall-marketplace": false`
- `"ruby-lsp@claude-plugins-official": false`

- [ ] **Step 2: Verify the change**

```bash
python3 -c "import json; d=json.load(open('$HOME/.claude/settings.json')); [print(k,v) for k,v in d['enabledPlugins'].items() if not v]"
```

Expected: The 4 disabled plugins listed with `False`

- [ ] **Step 3: Commit**

```bash
git add ~/.claude/settings.json
git commit -m "chore(claude): disable 4 unused plugins"
```

---

## Task 10: Final verification and push

- [ ] **Step 1: Verify token reduction**

```bash
echo "Global CLAUDE.md:" && wc -c ~/.claude/CLAUDE.md
echo "Project CLAUDE.md:" && wc -c ~/CLAUDE.md
echo "Rules:" && wc -c ~/.claude/rules/*.md
echo "Kept commands:" && find ~/.claude/commands -name "*.md" -not -path "*/_archive/*" | wc -l
echo "Remaining global skills (flat):" && ls ~/.claude/skills/*.md 2>/dev/null | wc -l
echo "Remaining project skills:" && ls .claude/skills/*.md 2>/dev/null | wc -l
```

Expected:
- Global CLAUDE.md: ~1000 bytes (was 3199)
- Project CLAUDE.md: ~2000 bytes (was 14227)
- Rules: 5 files (python, typescript, shell-functions, git-workflow, rust)
- Kept commands: 9 files
- Remaining global skills: 0 flat files (only directories)
- Remaining project skills: 4 files

- [ ] **Step 2: Push all commits**

```bash
git push
```

- [ ] **Step 3: Verify in a new session**

Start a new Claude Code session in `~/` and confirm:
- Reduced skill list in system prompt
- Rules load when editing relevant files
- Active commands still appear in `/` completion
