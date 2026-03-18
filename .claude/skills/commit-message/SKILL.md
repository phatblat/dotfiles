---
name: commit-message
description: |-
  Ship workflow: review changes, generate conventional commit messages, push, and create PRs.
  MUST BE USED when user says: "commit", "git commit", "commit this", "save changes", "commit message",
  "ship", "ship it", "push", "create PR", "pull request", "ready to merge", "deploy this",
  "stage changes", "what changed", "review my changes", "conventional commit",
  or after completing a coding task. Reviews changes, generates commit, optionally pushes and creates PR.
  NOT for git branching/rebasing (use git-workflow), code review (use review command),
  or deployment configuration (use deployment-assistant).
allowed-tools:
  - Bash
  - mcp__git__git_status
  - mcp__git__git_diff_unstaged
  - Read
  - AskUserQuestion
---

# Ship Workflow

## Overview

Complete shipping pipeline: review changes -> commit -> push -> PR (each step confirmed).

## Process

```
Phase 1: REVIEW   -> git status + diff, understand all changes
Phase 2: COMMIT   -> Generate conventional commit message, confirm, commit
Phase 3: PUSH     -> Push to remote (if requested)
Phase 4: PR       -> Create PR with summary (if requested)
```

## Phase 1: Review Changes

Before generating a commit message:

```bash
# 1. Check what's staged and untracked
git status

# 2. Review changes (staged + unstaged)
git diff --cached
git diff

# 3. Check recent commit style
git log --oneline -5
```

### Review Checklist
- Are all intended files staged?
- Are there files that should NOT be committed? (.env, large binaries, etc.)
- Do changes make sense as a single commit or should they be split?

## Format (Conventional Commits)

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Usage | Example |
|------|-------|---------|
| `feat` | New feature | `feat(auth): add OAuth2 login` |
| `fix` | Bug fix | `fix(api): handle null response` |
| `docs` | Documentation only | `docs(readme): update installation` |
| `style` | Formatting, no logic | `style: format with prettier` |
| `refactor` | Code restructure | `refactor(utils): extract helper` |
| `perf` | Performance | `perf(query): add index` |
| `test` | Tests | `test(auth): add login tests` |
| `chore` | Maintenance | `chore(deps): update packages` |
| `ci` | CI/CD | `ci: add GitHub Actions` |
| `build` | Build system | `build: update webpack config` |

## Rules

### Subject Line (First Line)

- **Max 50 characters**
- **Imperative mood**: "Add" not "Added" or "Adds"
- **No period at end**
- **Capitalize first letter**
- **Be specific**: "fix login button" > "fix bug"

### Scope (Optional)

- Component, module, or feature affected
- Lowercase, short
- Examples: `auth`, `api`, `ui`, `config`, `deps`

### Body (Optional)

- **Wrap at 72 characters**
- **Explain "what" and "why"**, not "how"
- **Separate from subject with blank line**
- Use bullet points for multiple changes

### Footer (Required)

- Always include Claude attribution
- Reference issues if applicable: `Closes #123`
- Note breaking changes: `BREAKING CHANGE: ...`

## Template

```
<type>(<scope>): <description>

<optional body explaining why this change was made>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Git Command Format

Use HEREDOC for proper formatting:

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add password reset flow

Implement forgot password functionality with email verification.
Users can now reset their password via a secure token sent by email.

Closes #42

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Examples

### Simple Fix

```
fix(button): correct hover state color

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Feature with Explanation

```
feat(search): add fuzzy matching

Implement Levenshtein distance for typo-tolerant search.
This improves UX when users mistype search queries.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Breaking Change

```
feat(api)!: change response format to JSON:API

BREAKING CHANGE: API responses now follow JSON:API specification.
All clients must update their parsers.

Migration guide: docs/migration-v2.md

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Anti-Patterns (Avoid)

```
❌ "fix stuff"
❌ "update code"
❌ "WIP"
❌ "misc changes"
❌ "asdf" (obviously)
❌ "Fixed the thing that was broken"
❌ Subject longer than 50 chars.....................
```

## Post-Commit Verification

After committing:

```bash
# Verify commit was created
git log -1

# Check nothing was missed
git status
```

## Phase 3: Push (Optional)

If user confirms push:

```bash
# Push to remote
git push origin HEAD

# If no upstream, set it
git push -u origin HEAD
```

**Always confirm before pushing.** Show which remote and branch.

## Phase 4: Create PR (Optional)

If user wants a PR:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
- [bullet points of changes]

## Test Plan
- [how to verify changes]

Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### PR Title Rules
- Max 70 characters
- Same format as commit subject: `type(scope): description`
- Use the body for details, not the title

### PR Body Template
```markdown
## Summary
[1-3 bullet points describing what changed and why]

## Test Plan
- [ ] [Steps to verify the changes work]

## Related Issues
Closes #[number] (if applicable)
```

**Always confirm PR title and body before creating.**
Return the PR URL when done.
