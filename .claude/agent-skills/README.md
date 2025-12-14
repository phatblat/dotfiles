# Agent Skills Library

Reusable capability modules that agents can invoke to perform specific tasks.

## Skills Registry

### Tools

#### `test-runner`
**Path**: `agent-skills/tools/test-runner.md`

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
**Path**: `agent-skills/tools/code-browser.md`

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
**Path**: `agent-skills/tools/shell-validator.md`

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
**Path**: `agent-skills/tools/rust-validator.md`

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
**Path**: `agent-skills/tools/doc-extractor.md`

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
**Path**: `agent-skills/tools/python-validator.md`

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
**Path**: `agent-skills/tools/format-converter.md`

**Purpose**: Convert data between different structured and semi-structured formats

**Supported Formats**: JSON, YAML, XML, CSV, TSV, TOML, Markdown, JSONL, Plain Text

**What It Does**:
- Converts data between supported formats with validation
- Detects source format (auto-detect or explicit)
- Transforms to target format with format-specific rules
- Validates output correctness and data integrity
- Returns converted data + validation report + preservation metrics
- Warns about lossy conversions
- Does NOT modify original data

**Used By**: `data-format-converter`, api-developer, documentation-generator

**Example Invocation**:
```
[invoke format-converter]
input: {
  "action": "convert",
  "sourceData": "{\"name\": \"Alice\", \"age\": 30}",
  "sourceFormat": "json",
  "targetFormat": "yaml"
}
```

---

## Future Skills Candidates

These archived agents should be converted to skills once the pattern is established:

- `go-expert.md` → Go-specific operations
- `container-expert.md` → Docker/container operations

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
