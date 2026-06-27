---
name: "git-commit"
description: "Create a git commit following the project's established style"
---

# git-commit

Use this skill when the user asks to run the migrated command `git-commit` or invokes `$git-commit`.

## Command Template

Create a git commit following the project's established style

## Combined Messages
If the user's message contains both `/git:commit` and additional instructions (e.g., "run tests against X"), execute the commit workflow first, then handle the additional instruction separately. Do not let extra context interfere with the commit flow.

## Git Expert Integration
For complex commit scenarios (merge commits, conflict resolution, commit history issues, interactive rebasing), consider using the Task tool with `git-expert` subagent for specialized git expertise.

## Efficiency Note:
This command intelligently reuses recent git:status results when available to avoid redundant operations. If you just ran /git:status, the commit process will be faster.

When git conventions are already documented in AGENTS.md/AGENTS.md, use them directly without verbose explanation.

All git commands are combined into a single bash call for maximum speed.

## Model Routing

This skill runs on haiku by default. After gathering the diff, evaluate complexity to decide whether to escalate:

**Simple (handle directly with haiku):**
- ≤ 3 files changed
- Single logical concern (all changes are clearly related)
- < 50 diff lines
- No ambiguous grouping decisions needed

**Complex (spawn an opus agent):**
- > 3 files changed with multiple logical concerns
- Ambiguous grouping — unclear how to split commits
- Large refactors touching many modules
- Merge conflicts or unusual git state

When escalating, spawn an Agent with `model: "opus"` and pass it:
- The full diff output (or stat summary if too large)
- The recent commit log (for convention matching)
- The AGENTS.md commit conventions (if any)
- Instructions to follow the Steps below and return the commit commands to execute

## Branch Safety Guard (run BEFORE Step 1)

Before gathering status or committing, check the current branch and repo:

```bash
echo "branch=$(git rev-parse --abbrev-ref HEAD) root=$(git rev-parse --show-toplevel) home=$HOME commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)"
```

If `branch` is **`main`** or **`master`**, the guard applies — UNLESS an exception holds.

**Exceptions (skip the guard, commit normally without asking):**
- `root` equals `$HOME` — the dotfiles repo, OR
- `commits` < 100 — a young repo where branch ceremony adds no value.

**When the guard applies** (protected `main`/`master`, neither exception met):
1. STOP — do not stage or commit yet.
2. Warn the user they are about to commit directly to the protected `<branch>` branch.
3. Offer to create a branch and require confirmation (use `AskUserQuestion`). Propose a branch name derived from the pending change, e.g. `<type>/<short-slug>` matching the commit type you'd use.
4. On confirmation: `git checkout -b <branch>`, then continue to Step 1.
5. If the user explicitly declines branching and insists on `main`, proceed only after that explicit confirmation.

For any other (non-protected) branch, proceed straight to Step 1.

## Steps:
1. Check if the previous message contains git:status results:
   - Look for patterns like "Git Status Analysis", "Modified Files:", "Uncommitted Changes:"
   - If found and recent (within last 2-3 messages): Reuse those results
   - If not found or stale: Run a single combined git command:
   !git --no-pager status --porcelain=v1 && echo "---STAT---" && git --no-pager diff --stat 2>/dev/null && echo "---DIFF---" && git --no-pager diff 2>/dev/null | head -2000 && echo "---LOG---" && git --no-pager log --oneline -5
   - Note: Only skip git status if you're confident the working directory hasn't changed
   - Note: Full diff is capped at 2000 lines to prevent context flooding. The stat summary above shows all changed files
2. **Evaluate complexity** — apply the Model Routing heuristics above. If complex, delegate to opus agent and execute its recommendations. Otherwise continue.
3. Review the diff output to verify:
   - No sensitive information (passwords, API keys, tokens) in the changes
   - No debugging code or console.log statements left in production code
   - No temporary debugging scripts (test-*.js, debug-*.py, etc.) created by Codex
   - No temporary files or outputs in inappropriate locations (move to project's temp directory or delete)
   - All TODO/FIXME comments are addressed or intentionally left
4. **Group changes logically** — analyze all changed files and determine if they should be split into multiple commits:
   - Each commit should represent one coherent change (a bug fix, a config update, a new feature, a refactor)
   - Unrelated changes MUST be committed separately (e.g., a tool version bump + a shell function fix = 2 commits)
   - Related changes belong together (e.g., a function change + its doc update = 1 commit)
   - If the grouping is ambiguous, present the proposed groups to the user and ask for confirmation before committing
   - If all changes are logically related, a single commit is fine
5. Use documented git commit conventions from AGENTS.md/AGENTS.md
   - If conventions are not documented, analyze recent commits and document them
6. If the project uses ticket/task codes, ask the user for the relevant code if not clear from context
7. Check if README.md or other documentation needs updating to reflect the changes (see "Documentation Updates" section below)
8. Run tests and lint commands to ensure code quality (unless just ran before this command)
9. For each logical group: stage the relevant files, create a commit with an appropriate message
10. Verify all commits succeeded - Report with ✅ success indicator
11. Check if any post-commit hooks need to be considered (e.g., pushing to remote, creating PR)

## Documentation Updates:
If changes warrant doc updates (new features, API changes), update relevant docs in the same commit group.

## Commit Convention Documentation:
Only when conventions are NOT already documented in AGENTS.md: analyze `git log --oneline -20` and document the observed pattern in AGENTS.md under "Git Commit Conventions". Once documented, use directly without explanation.
