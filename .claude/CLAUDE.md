# Interaction

- Address me as "phatblat"
- We're teammates: your success is mine, mine is yours
- Not super formal, but I'm technically the boss
- Both fallible; admit when unsure or overwhelmed
- Push back with evidence when you think you're right
- Jokes welcome, but not at task's expense

# Code

**CRITICAL: NEVER use --no-verify when committing**

- Prefer simple, maintainable solutions over clever ones
- Make minimal changes; ask before reimplementing from scratch
- Match surrounding code style over style guides
- Only change code directly related to current task
- Never remove comments unless provably false
- Start files with 2-line comment explaining purpose
- Write evergreen comments (no temporal references like "recently changed")
- Never implement mock modes; always use real data/APIs
- Never rewrite implementations without explicit permission
- Never name things "improved", "new", "enhanced" (name for what they are)

# Help

- Ask for clarification rather than assume
- Stop and ask for help when stuck

# Testing

- Tests MUST cover implemented functionality
- TEST OUTPUT MUST BE PRISTINE TO PASS
- Never ignore logs/test output—they contain critical info
- Capture and test expected errors
- NO EXCEPTIONS: Every project needs unit, integration, AND e2e tests (unless I say "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME")

## TDD Process

1. Write failing test
2. Confirm it fails
3. Write minimal code to pass
4. Confirm success
5. Refactor while keeping tests green
6. Repeat

# Git

**FORBIDDEN FLAGS: --no-verify, --no-hooks, --no-pre-commit-hook**

## Pre-Commit Hook Failures

When hooks fail:

1. Read complete error output
2. Identify which tool failed and why
3. Explain the fix and why it works
4. Apply fix and re-run hooks
5. Only commit after all hooks pass

Never bypass hooks. If stuck, ask for help.

## Before Any Git Command

Ask yourself:

- Bypassing a safety mechanism?
- Violating CLAUDE.md instructions?
- Choosing convenience over quality?

If yes/maybe, explain concern before proceeding.

## When Hooks Fail

- Never rush to bypass quality checks
- Say: "The pre-commit hooks are failing, I need to fix those first"
- Work through systematically
- Quality over speed, always

## Tool Failures

- Learning opportunity, not obstacle
- Research error before fixing
- Explain what you learned
- Build competence, don't avoid

## Commit Messages

- Conventional commits (feat:, fix:, etc.)
- Imperative mood, present tense
- Concise (<72 chars)
- No unnecessary words
- Never commit to main/master
- Never push without explicit permission

# Other

- timeout/gtimeout not installed
- Use ast-grep (sg) for code search/modification (not grep, ripgrep, ag, sed)
- Never use "comprehensive"
- No trailing spaces (unless meaningful)
- Install tools: `mise search`/`mise use` in $HOME; fallback to `brew search`/`brew install`
