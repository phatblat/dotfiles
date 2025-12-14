# Interaction

- We're teammates: your success is mine, mine is yours
- Not super formal, but I'm technically the boss
- Both fallible; admit when unsure or overwhelmed
- Push back with evidence when you think you're right
- Never use the word "comprehensive"

# Code

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

## Topic Branches

**For getditto organization repos**: `ben/<linear-ticket>/kebab-lower-case-description`

- Linear ticket: lowercase issue ID (e.g., TEAM-1234 → team-1234)
- Description: brief title summarizing the effort
- Example: `ben/team-1234/add-user-authentication`

**For all other repos**: `ben/kebab-lower-case-description`

- Example: `ben/fix-authentication-bug`

## Ticket Workflow

When asked to start work on a ticket, always:

1. Implement the change
2. Test the build
3. Run any related tests
4. Lint the code changed (use lint make targets or just recipes)
5. Commit the code

Wait for review before creating PRs—phatblat always reviews first.

## Commit Messages

- Conventional commits (feat:, fix:, etc.)
- Imperative mood, present tense
- Concise (<72 chars)
- No unnecessary words
- Never commit to main/master
- Never push without explicit permission

# Agent Skills

Available reusable agent capabilities (see `.claude/agent-skills/`):

- **test-runner** — Execute test suites and report results
  - Detects framework (cargo, npm, pytest, go, gradle, maven, dotnet)
  - Returns raw test output, exit code, duration
  - Used by: implementor, project-planner, any testing agents

- **code-browser** — Search and locate code in codebase
  - Search types: implementation, usage, pattern, concept, inheritance
  - Returns file paths, line numbers, code snippets (grouped by relevance)
  - Used by: research agents, code-analyzer, implementor, architecture agents

- **shell-validator** — Validate shell scripts (Bash/sh/Zsh)
  - Checks: syntax, portability (macOS/Linux), best practices, security, formatting
  - Returns structured issues with locations and suggestions
  - Used by: shell-expert, script-reviewer, automation agents

- **rust-validator** — Validate Rust code (cargo projects)
  - Checks: compilation, clippy lints, formatting, dependency audit
  - Returns structured issues with locations and clippy codes
  - Used by: rust-expert, code-reviewer, performance-optimizer

- **doc-extractor** — Extract documentation information from source code
  - Extraction types: comments, structure, examples, undocumented, all
  - Returns: APIs, doc coverage %, code examples, documentation gaps, suggested structure
  - Used by: tech-writer, documentation-reviewer, api-designer

- **python-validator** — Validate Python code (Black, Pylint, mypy, bandit)
  - Checks: formatting, linting, type checking, security, dependency audit
  - Returns structured issues with locations and suggestions
  - Used by: python-expert, code-reviewer, security-auditor

- **format-converter** — Convert data between different formats
  - Supported: JSON, YAML, XML, CSV, TSV, TOML, Markdown, JSONL, Plain Text
  - Returns: converted data + validation report + data integrity metrics
  - Used by: data-format-converter, api-developer, documentation-generator

- **ditto-docs-search** — Search Ditto SDK documentation
  - Search types: general, api, guide, example, dql
  - Filters: platform (Swift, JS, Rust, C++, Java, Kotlin, Flutter, C#), version
  - Returns: documentation pages, URLs, excerpts, warnings about broken/outdated links
  - Used by: ditto-docs, ditto-sdk-architect, tech-writer

- **dql-validator** — Validate Ditto Query Language (DQL) queries
  - Validates: syntax, compatibility, optimization
  - Detects: legacy patterns, unsupported operators, indexing opportunities
  - Returns: validation report with issues and suggestions
  - Used by: dql-expert, ditto-sdk-architect, implementor

- **linear-searcher** — Search Linear issues with relationships
  - Filters: status, assignee, label, project, team, cycle
  - Returns: matched issues with linked PRs, tickets, parent/child relationships
  - Used by: linear-expert, project-planner, implementor

- **notion-searcher** — Search Notion pages and databases
  - Search types: pages, databases, title, tags, content
  - Filters: workspace, database, tag, status
  - Returns: matched content with hierarchy and metadata
  - Used by: notion-expert, tech-writer, project-planner

- **git-executor** — Execute git commands with safety checks
  - Commands: commit, branch, checkout, merge, rebase, push, pull, fetch, log, diff, status, stash
  - Safety: prevents main commits, unsafe force-push
  - Returns: exit code, stdout/stderr, metadata, duration
  - Used by: github-expert, implementor, project-planner

- **slack-searcher** — Search and retrieve Slack messages and files
  - Search types: messages, files, threads, all
  - Filters: channel, user, date range, content type
  - Returns: matched messages with metadata, threads, attachments, reactions
  - Used by: slack-expert, team-analyst, knowledge-base-assistant

- **go-validator** — Validate Go projects for correctness and quality
  - Checks: compilation (go build), linting (go vet, golangci-lint)
  - Includes: formatting (go fmt), dependencies (go mod), tests (go test)
  - Returns: structured validation report with line-specific issues
  - Used by: go-expert, code-reviewer, performance-optimizer

- **js-validator** — Validate JavaScript/TypeScript projects for code quality
  - Checks: linting (ESLint), formatting (Prettier), types (tsc), deps (npm audit), tests
  - Frameworks: React, Vue, Angular, Next.js, Node.js, React Native (auto-detected)
  - Returns: structured issues with locations, type errors, vulnerabilities
  - Used by: js-expert, code-reviewer, frontend-developer

- **swift-validator** — Validate Swift code for correctness, style, and build integrity
  - Checks: compilation (swiftc), linting (SwiftLint), formatting (SwiftFormat), build (xcodebuild)
  - Projects: SPM (Package.swift), Xcode projects/workspaces (auto-detected)
  - Includes: dependency validation, XCTest execution and coverage
  - Used by: swift-expert, code-reviewer, ios-developer

_More skills coming: language-specific validators (C++), container operations_

# Other

- timeout/gtimeout not installed
- Use ast-grep (sg) for code search/modification (not grep, ripgrep, ag, sed)
- No trailing spaces (unless meaningful)
- Install tools: `mise search`/`mise use` in $HOME; fallback to `brew search`/`brew install`
- Use `mise` for tool management @~/.config/mise/config.toml
