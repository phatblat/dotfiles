# Agent Skills Library

Reusable capability modules that agents can invoke to perform specific tasks.

## Skills Registry

### Tools

#### `test-runner`
**Path**: `~/.claude/skills/test-runner.md`

**Purpose**: Execute test suites and report results

**Supported Frameworks**: Make, npm, pytest, cargo, go test, gradle, maven, dotnet, rake/rspec

**What It Does**:
- Detects appropriate test command based on project structure
- Executes tests and captures output
- Returns exit code, stdout, stderr, duration
- Does NOT analyze failures or suggest fixes

**Used By**: `implementor`, `project-planner`, any testing agent

**Example Invocation**:
```
[invoke test-runner]
input: {
  "action": "run-tests",
  "testFramework": "auto"
}
```

---

#### `code-browser`
**Path**: `~/.claude/skills/code-browser.md`

**Purpose**: Search and locate code in a codebase

**Search Types**: implementation, usage, pattern, concept, inheritance

**What It Does**:
- Searches for code matching specific criteria
- Groups results by relevance (primary implementations vs. usage)
- Returns file paths, line numbers, code snippets
- Does NOT analyze or interpret findings

**Used By**: `implementor`, `research-agent`, `code-analyzer`, architecture agents

**Example Invocation**:
```
[invoke code-browser]
input: {
  "action": "search",
  "query": "payment processing",
  "searchType": "concept"
}
```

---

#### `shell-validator`
**Path**: `~/.claude/skills/shell-validator.md`

**Purpose**: Validate shell scripts for correctness, portability, and best practices

**Validation Types**: syntax, portability, best-practices, security, formatting

**What It Does**:
- Runs shellcheck to detect syntax and logic errors
- Checks for macOS vs Linux portability issues
- Validates against best practices and security standards
- Returns structured issues with locations and suggestions
- Does NOT modify or rewrite scripts

**Used By**: `shell-expert`, script-reviewer, automation-developer

**Example Invocation**:
```
[invoke shell-validator]
input: {
  "action": "validate",
  "scriptPath": "deploy.sh",
  "checks": "all",
  "targetPlatforms": ["macos", "linux"]
}
```

---

#### `rust-validator`
**Path**: `~/.claude/skills/rust-validator.md`

**Purpose**: Validate Rust code for correctness, style, and performance

**Validation Types**: compile, clippy, formatting, dependency audit

**What It Does**:
- Compiles the project to catch errors (cargo build)
- Runs clippy to detect performance and style issues
- Checks formatting compliance (cargo fmt)
- Audits dependencies for vulnerabilities (cargo audit)
- Returns structured issues with locations and suggestions
- Does NOT modify code or auto-format

**Used By**: `rust-expert`, code-reviewer, performance-optimizer

**Example Invocation**:
```
[invoke rust-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "toolchain": "stable"
}
```

---

#### `doc-extractor`
**Path**: `~/.claude/skills/doc-extractor.md`

**Purpose**: Extract documentation-relevant information from source code

**Extraction Types**: comments, structure, examples, undocumented, all

**What It Does**:
- Extracts documentation comments and docstrings
- Parses code structure and public APIs
- Identifies undocumented code items
- Extracts and validates code examples
- Suggests documentation structure
- Returns structured extraction data
- Does NOT generate documentation

**Used By**: `tech-writer`, documentation-reviewer, api-designer

**Example Invocation**:
```
[invoke doc-extractor]
input: {
  "action": "extract",
  "sourcePath": "src/lib.rs",
  "language": "rust",
  "extractTypes": "all"
}
```

---

#### `python-validator`
**Path**: `~/.claude/skills/python-validator.md`

**Purpose**: Validate Python code for style, types, and security

**Validation Types**: format, lint, types, security, dependencies

**What It Does**:
- Checks formatting with Black/PEP 8
- Runs Pylint/Ruff for code quality
- Validates type hints with mypy
- Detects security issues with bandit
- Checks for vulnerable/outdated dependencies
- Returns structured issues with locations and suggestions
- Does NOT modify code or auto-format

**Used By**: `python-expert`, code-reviewer, security-auditor

**Example Invocation**:
```
[invoke python-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "pythonVersion": "3.13"
}
```

---

#### `format-converter`
**Path**: `~/.claude/skills/format-converter.md`

**Purpose**: Convert data between different structured and semi-structured formats

---

#### `ditto-docs-search`
**Path**: `~/.claude/skills/ditto-docs-search.md`

**Purpose**: Search Ditto SDK documentation and retrieve API references, guides, and examples

**Supported Search Types**: general, api, guide, example, dql

**What It Does**:
- Searches docs.ditto.live for Ditto documentation
- Returns documentation pages with URLs and excerpts
- Supports platform-specific filtering (Swift, JS, Rust, C++, Java, Kotlin, Flutter, C#)
- Includes SDK version selection (latest, v4, v5-preview)
- Detects broken links and outdated content warnings
- Does NOT modify documentation

**Used By**: `ditto-docs`, ditto-sdk-architect, tech-writer, documentation-reviewer

**Example Invocation**:
```
[invoke ditto-docs-search]
input: {
  "action": "search",
  "query": "how to set up sync",
  "searchType": "guide"
}
```

---

#### `dql-validator`
**Path**: `~/.claude/skills/dql-validator.md`

**Purpose**: Validate Ditto Query Language (DQL) queries for syntax, compatibility, and optimization

**Validation Types**: syntax, compatibility, optimization, all

**What It Does**:
- Validates DQL query syntax against language rules
- Checks compatibility with DQL feature set
- Suggests performance optimizations
- Detects legacy query builder patterns
- Returns validation report with issues and suggestions
- Does NOT modify queries

**Used By**: `dql-expert`, ditto-sdk-architect, implementor

**Example Invocation**:
```
[invoke dql-validator]
input: {
  "action": "validate",
  "query": "SELECT * FROM users WHERE age > 18",
  "validateFor": "all"
}
```

---

#### `linear-searcher`
**Path**: `~/.claude/skills/linear-searcher.md`

**Purpose**: Search Linear issues with relationships to pull requests, tickets, and logs

**Search Categories**: content, assignee, label, status, cycle

**What It Does**:
- Searches Linear issues by multiple criteria
- Returns matched issues with metadata and relationships
- Retrieves linked PRs, Zendesk tickets, parent/child issues
- Supports filtering by project, team, cycle, status
- Handles issue dependencies and cross-references
- Does NOT modify issues

**Used By**: `linear-expert`, project-planner, implementor

**Example Invocation**:
```
[invoke linear-searcher]
input: {
  "action": "search",
  "query": "authentication",
  "searchBy": "content",
  "includeLinks": true
}
```

---

#### `notion-searcher`
**Path**: `~/.claude/skills/notion-searcher.md`

**Purpose**: Search Notion workspace for pages, databases, and documentation

**Search Types**: all, pages, databases, title, tags, content

**What It Does**:
- Searches Notion for pages and database entries
- Returns matched content with metadata and hierarchy
- Supports filtering by workspace, database, tag, status
- Includes page relationships (parent/child)
- Provides content previews (optional)
- Does NOT create or modify pages

**Used By**: `notion-expert`, tech-writer, project-planner

**Example Invocation**:
```
[invoke notion-searcher]
input: {
  "action": "search",
  "query": "meeting notes",
  "searchIn": "pages",
  "includeContent": true
}
```

---

#### `git-executor`
**Path**: `~/.claude/skills/git-executor.md`

**Purpose**: Execute git commands and return structured results with safety checks

**Supported Commands**: commit, branch, checkout, merge, rebase, push, pull, fetch, log, diff, status, stash, reset

**What It Does**:
- Executes git commands with timeout protection
- Returns exit code, stdout, stderr, execution time
- Parses output for metadata
- Enforces safety checks (prevents main commits, unsafe force-push)
- Detects merge conflicts and destructive operations
- Does NOT interpret results

**Used By**: `github-expert`, implementor, project-planner

**Example Invocation**:
```
[invoke git-executor]
input: {
  "action": "execute",
  "command": "commit",
  "args": ["-m", "feat: new feature"]
}
```

---

#### `slack-searcher`
**Path**: `~/.claude/skills/slack-searcher.md`

**Purpose**: Search and retrieve messages, files, and conversations from Slack workspaces

**Search Types**: messages, files, threads, all

**What It Does**:
- Searches Slack messages by keywords, users, channels, date ranges
- Retrieves files by filename or metadata
- Fetches threaded conversations with full reply context
- Returns matched results with metadata and attachments
- Includes message reactions and thread information
- Does NOT create, edit, or delete messages

**Used By**: `slack-expert`, team-analyst, knowledge-base-assistant

**Example Invocation**:
```
[invoke slack-searcher]
input: {
  "action": "search",
  "query": "deployment",
  "filters": {"channel": "engineering"},
  "includeThreads": true
}
```

---

#### `go-validator`
**Path**: `~/.claude/skills/go-validator.md`

**Purpose**: Validate Go projects for correctness, style, and dependency health

**Validation Types**: compile, lint, format, deps, test, all

**What It Does**:
- Compiles projects using `go build` to detect errors
- Runs `go vet` and `golangci-lint` for code quality
- Checks formatting with `gofmt`
- Validates dependencies with `go mod`
- Runs tests and reports coverage
- Returns structured issues with line-specific locations

**Used By**: `go-expert`, code-reviewer, performance-optimizer

**Example Invocation**:
```
[invoke go-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "goVersion": "1.21"
}
```

---

#### `js-validator`
**Path**: `~/.claude/skills/js-validator.md`

**Purpose**: Validate JavaScript and TypeScript projects for code quality, style, and type correctness

**Validation Types**: lint, format, types, deps, test, all

**What It Does**:
- Runs ESLint to detect code quality issues
- Checks formatting with Prettier
- Validates types using TypeScript compiler (tsc)
- Audits dependencies for security vulnerabilities (npm audit)
- Runs tests with Jest/Vitest/Mocha
- Detects frameworks automatically (React, Vue, Angular, Next.js, Node.js, React Native)
- Returns structured issues with locations and suggestions

**Used By**: `js-expert`, code-reviewer, frontend-developer

**Example Invocation**:
```
[invoke js-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "language": "typescript"
}
```

---

#### `swift-validator`
**Path**: `~/.claude/skills/swift-validator.md`

**Purpose**: Validate Swift code for correctness, style, and build integrity

**Validation Types**: compile, lint, format, build, deps, test, all

**What It Does**:
- Compiles Swift code using `swiftc` or Xcode
- Runs SwiftLint to detect style violations and best practices
- Checks formatting with SwiftFormat
- Builds Xcode projects/workspaces with xcodebuild
- Validates Swift Package Manager dependencies
- Runs XCTest suites and reports coverage
- Detects project type automatically (SPM, Xcode project, workspace)

**Used By**: `swift-expert`, code-reviewer, ios-developer

**Example Invocation**:
```
[invoke swift-validator]
input: {
  "action": "validate",
  "projectPath": ".",
  "checks": "all",
  "scheme": "MyApp"
}
```

---

## Future Skills Candidates

These archived agents should be converted to skills once the pattern is established:

- `container-expert.md` → Docker/container operations
- `cpp-expert.md` → C++ validation

---

## Skill Development Guidelines

### Structure

Each skill is a markdown file with:

1. **Header**: Name and one-line description
2. **Capability**: What the skill does
3. **Supported Options**: Frameworks, languages, tools it handles
4. **Usage Protocol**: How agents invoke it
5. **Input/Output Contract**: Clear data format
6. **Constraints**: What it explicitly does NOT do
7. **Error Handling**: How it reports failures

### Design Principles

**Skills are tools, not agents:**
- No autonomous reasoning
- No decision-making
- No modification of behavior based on context

**Skills are focused:**
- One primary responsibility
- Clear input/output contract
- Reusable across multiple agents

**Skills are transparent:**
- Return raw results (no interpretation)
- No filtering or summarization
- Complete error messages included

### Example Usage in Agents

```yaml
---
name: my-agent
skills:
  - test-runner
  - code-browser
---

When the agent needs tests:
[invoke test-runner skill]

When the agent needs to search code:
[invoke code-browser skill]
```

---

## Version

Created: 2025-12-13
Last Updated: 2025-12-14
