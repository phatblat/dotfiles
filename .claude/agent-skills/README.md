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

## Future Skills Candidates

These archived agents should be converted to skills once the pattern is established:

- `code-browser.md` → Browse/search code
- `code-converter.md` → Transform between formats
- `go-expert.md` → Go-specific operations
- `rust-expert.md` → Rust-specific operations
- `shell-expert.md` → Shell script validation
- `container-expert.md` → Docker/container operations
- `tech-writer.md` → Documentation generation

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
Last Updated: 2025-12-13
