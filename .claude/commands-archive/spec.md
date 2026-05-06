---
name: spec
description: Create and manage software specifications and implementation plans
argument_hint:
  [read|create|update|summarize|add <details>|<specification description>]
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
  - Skill
  - mcp__github__*
  - mcp__ditto__*
model: sonnet
---

<default_to_action>
Execute spec operations immediately. Default action (no arguments) is to summarize current specs and suggest next steps. Create the specs/ directory and files as needed.
</default_to_action>

<investigate_before_answering>
Read existing spec files before making updates. Understand the current state of specifications before suggesting changes or asking questions.
</investigate_before_answering>

<use_parallel_tool_calls>
Spawn multiple Task agents concurrently for independent work: parallel file reads, concurrent research queries, simultaneous code analysis. Combine results before writing.
</use_parallel_tool_calls>

<track_progress_with_todos>
Use TaskCreate to track spec creation progress. Create tasks for: research tasks, file creation, question gathering, user interviews. Use TaskUpdate to mark tasks complete as you proceed.
</track_progress_with_todos>

# Software Specification Management

Manage software specifications in a `specs/` subdirectory.

## Primary Files

| File                     | Purpose                                              |
| ------------------------ | ---------------------------------------------------- |
| `SPECIFICATION.md`       | What the software should do and how it should behave |
| `IMPLEMENTATION_PLAN.md` | Step-by-step tasks with `- [ ]` checkboxes           |
| `TEST_PLAN.md`           | Unit, integration, manual, and performance tests     |
| `OPEN_ISSUES.md`         | Questions, bugs, pending decisions, research needed  |
| `DECISION_LOG.md`        | Append-only log of user decisions (for human review) |

## Command Routing

| Input             | Action                                               |
| ----------------- | ---------------------------------------------------- |
| `/spec`           | Summarize + suggest next steps                       |
| `/spec read`      | Read and present all spec files                      |
| `/spec create`    | Interview user, create initial specs                 |
| `/spec update`    | Sync specs with conversation/code changes            |
| `/spec summarize` | Brief progress report (no suggestions)               |
| `/spec add <X>`   | Add specific content (tests, features, etc.)         |
| `/spec implement` | Execute tasks continuously until blocked or complete |
| `/spec <text>`    | Create specs from description, list open questions   |

**Disambiguation**: If input starts with a keyword (`read`, `create`, `update`, `summarize`, `add`, `implement`), treat as command. Otherwise treat as specification description.

## Operations

### No Arguments (Default)

1. Check for `specs/` directory
2. If exists: Read files → summarize goals, progress %, open issues → suggest next steps
3. If missing: Explain purpose, offer to create

### read

Read the four editable files (in parallel), plus any referenced files. Present organized summary. Skip DECISION_LOG.md.

### create

1. Check for existing specs (ask: replace, extend, or cancel?)
2. Create `specs/` directory, template files, and DECISION_LOG.md with marker:

   ```
   # Decision Log

   <!-- LOG_END -->
   ```

3. Interview user: project type, platforms, features, UI, constraints, integrations
4. Update files from responses, append each decision to DECISION_LOG.md
5. **Annotate IMPLEMENTATION_PLAN.md** with `[agent:]`, `[skill:]`, `[cmd:]`, `[parallel]`, `[depends:]` tags (see Tool & Parallelism Guidance section)
6. Continue until implementation-ready
7. Track unknowns in OPEN_ISSUES.md (remove when answered)

### update

1. Read existing specs
2. Analyze conversation for: new requirements, clarifications, decisions, answered questions
3. Scan project files for: implementation progress, new patterns, test results
4. Update specs, mark completed tasks, **delete resolved items from OPEN_ISSUES.md**
5. **Review/add tool annotations** in IMPLEMENTATION_PLAN.md for new or modified tasks
6. Append decisions to DECISION_LOG.md
7. Report changes made

### summarize

Read specs → present: **Goals** | **Progress** (X/Y tasks, %) | **Testing** status | **Open Issues** count

### add \<details\>

1. Parse content type (tests, features, requirements, constraints)
2. Read relevant spec files
3. If sufficient info: add content, append decision to DECISION_LOG.md, report what was added
4. If insufficient: ask clarifying questions, track in OPEN_ISSUES.md

### implement

Execute tasks from IMPLEMENTATION_PLAN.md **continuously until blocked**. This command bridges specification and implementation.

<continuous_execution>
Continue implementing tasks automatically. Only stop when:

- All tasks are complete
- A blocker is encountered (missing dependency, unclear requirement, failing tests)
- User input is required (design decision, external action needed)

There is no need to pause after each task or wait for user confirmation. Proceed through the plan as long as tasks are executable.
</continuous_execution>

**Workflow** (loop until blocked or complete):

1. Read `specs/IMPLEMENTATION_PLAN.md` and `specs/TEST_PLAN.md`
2. Find the first incomplete task (line starting with `- [ ]`)
3. If no incomplete tasks remain → report completion summary and stop
4. Identify phase, context, and any `[depends:]` constraints
5. Check if dependencies are satisfied; if not, skip to next executable task
6. **Execute the task** - write code, create files, run commands as needed
7. After successful completion:
   - Mark the task complete (`- [x]`) in IMPLEMENTATION_PLAN.md
   - Update TEST_PLAN.md if tests were added or test status changed
   - Update SPECIFICATION.md if implementation revealed new constraints
8. **Continue to next task** (return to step 2)

**Spec File Maintenance**:

- Update IMPLEMENTATION_PLAN.md immediately after each task completion
- Update TEST_PLAN.md when: tests are written, tests pass/fail, coverage changes
- Add discovered issues to OPEN_ISSUES.md as encountered
- Keep files in sync - don't batch updates

**Task Execution Rules**:

- Actually implement the task, don't just describe what to do
- Use appropriate tools: Write/Edit for code, Bash for commands, Task for complex subtasks
- If a task is ambiguous, check SPECIFICATION.md and TEST_PLAN.md for requirements
- Run relevant tests after code changes when practical
- If blocked: report the blocker, add to OPEN_ISSUES.md, and stop

**Stopping Conditions** (report and await user input):

- Blocker encountered (describe what's needed to proceed)
- Design decision required that isn't covered by SPECIFICATION.md
- External action needed (API key, service setup, manual verification)
- Tests failing with unclear fix
- All tasks complete

**Progress Reporting**:

- Brief status after completing each task (1 line: task name + outcome)
- Detailed report only when stopping (tasks completed, current state, next steps or blockers)

**Scope**: Unlike other `/spec` commands, `implement` CAN modify source files outside `specs/`. It's the bridge from planning to execution.

### \<description\>

1. Create `specs/` if needed (including empty DECISION_LOG.md)
2. Extract: project type, requirements, constraints from description
3. Create preliminary content in the four editable files
4. **Annotate IMPLEMENTATION_PLAN.md** with tool recommendations and `[parallel]` markers
5. Generate and present open questions
6. As user answers questions: update specs, append to DECISION_LOG.md, delete resolved items from OPEN_ISSUES.md

## Parallel Execution Patterns

| Operation       | Spawn These Tasks Concurrently                                          |
| --------------- | ----------------------------------------------------------------------- |
| read            | Read all 4 spec files                                                   |
| create          | Research similar projects, look up platform docs, analyze existing code |
| update          | Scan source files, check test coverage, review conversation             |
| \<description\> | Research patterns, look up APIs, analyze project structure              |

## File Templates

Templates use minimal structure. Expand sections as needed during creation.

**SPECIFICATION.md**: Overview, Goals, Target Platforms, Features (by category), User Interface, Technical Requirements, Constraints, Out of Scope

**IMPLEMENTATION_PLAN.md**: Phases with component/module sections, `- [ ]` task checkboxes, Dependencies, Milestones, Tool Recommendations (see below)

**TEST_PLAN.md**: Unit Tests (by component), Integration Tests, Manual Tests (by feature), Edge Cases, Performance Tests

**OPEN_ISSUES.md**: Questions Needing Answers, Bugs to Fix, Decisions Pending, Research Needed, Notes. **Remove items when resolved** (history is in DECISION_LOG.md).

## Decision Log

`DECISION_LOG.md` is an **append-only** file for human review. **Only the /spec command updates this file** - it tracks project specification decisions, not changes to other tools or commands.

**When to append**: After changes to files in `specs/` caused by:

- User answering an open question about the project
- User directing a specification change
- User making a design decision for the project

**Format** (one line per decision):

```
YYYY-MM-DD HH:MM | <file changed> | <brief description of decision>
```

**Example entries**:

```
2026-01-17 14:30 | SPECIFICATION.md | App name set to "Ditto Recipes"
2026-01-17 14:32 | IMPLEMENTATION_PLAN.md | Added cook mode with voice control per user request
2026-01-17 14:35 | OPEN_ISSUES.md | Resolved: tablet layout is priority
```

**Append using Edit tool** (avoids Bash permission prompts):

1. Use Grep to verify the marker exists: `Grep(pattern="LOG_END", path="specs/DECISION_LOG.md")`
2. Edit to replace the marker:
   - `old_string`: `<!-- LOG_END -->`
   - `new_string`: `YYYY-MM-DD HH:MM | <file> | <description>\n<!-- LOG_END -->`

Grep satisfies the "read before edit" requirement with minimal tokens.

## Scope Constraints

**Default**: Only modify files in `specs/`. No code implementation, no source file changes.

**Exception**: `/spec implement` CAN modify source files - it executes implementation tasks.

**Can read**: Any project files for context. For DECISION_LOG.md, use Grep to find the marker (minimal tokens).
**Can use**: Web search, GitHub, Ditto docs, Dash, Linear

## Skills

Invoke proactively when relevant:

| Skill          | Trigger                            |
| -------------- | ---------------------------------- |
| `dash`         | API/framework documentation lookup |
| `write-dql`    | Ditto Query Language in specs      |
| `ditto-docs`   | Ditto SDK features                 |
| `using-github` | Research implementations/issues    |
| `linear`       | Link to Linear issues              |

## IMPLEMENTATION_PLAN.md: Tool & Parallelism Guidance

When creating or updating IMPLEMENTATION_PLAN.md, annotate tasks with recommended tools and parallel execution opportunities.

### Task Annotations

For each task or phase, add inline annotations:

| Annotation     | Meaning                                  | Example                                        |
| -------------- | ---------------------------------------- | ---------------------------------------------- |
| `[skill: X]`   | Load skill X before this task            | `- [ ] Write DQL queries [skill: write-dql]`   |
| `[agent: X]`   | Use subagent X for this task             | `- [ ] Create iOS views [agent: swift-expert]` |
| `[cmd: /X]`    | Run command /X                           | `- [ ] Check CI status [cmd: /cicheck]`        |
| `[parallel]`   | Can run with adjacent `[parallel]` tasks | `- [ ] Create user model [parallel]`           |
| `[depends: N]` | Must complete after task N               | `- [ ] Integration tests [depends: 3.1, 3.2]`  |

### Common Tool Recommendations

Match task patterns to tools:

| Task Pattern          | Recommendation                                          |
| --------------------- | ------------------------------------------------------- |
| Swift/iOS/macOS code  | `[agent: swift-expert]` or `[skill: apple-development]` |
| Android/Kotlin code   | `[agent: android-expert]`                               |
| Rust code             | `[agent: rust-expert]`                                  |
| Go code               | `[agent: go-expert]`                                    |
| C++/CMake             | `[agent: cpp-expert]`, `[agent: cmake-expert]`          |
| Python code           | `[agent: python-expert]`                                |
| JavaScript/TypeScript | `[agent: js-expert]`                                    |
| C#/.NET/MAUI          | `[agent: dotnet-expert]`                                |
| Flutter/Dart          | `[agent: flutter-dart-expert]`                          |
| Shell scripts         | `[agent: shell-expert]`                                 |
| API integration       | `[agent: rest-expert]`                                  |
| Database/DQL queries  | `[agent: dql-expert]`, `[skill: write-dql]`             |
| Ditto SDK work        | `[agent: ditto-sdk-expert]`, `[agent: ditto-docs]`      |
| UI/UX design          | `[agent: ui-designer]`                                  |
| Docker/containers     | `[agent: container-expert]`                             |
| Linux systems         | `[agent: linux-expert]`                                 |
| macOS config          | `[agent: macos-expert]`                                 |
| Git/GitHub ops        | `[agent: github-expert]`, `[skill: using-github]`       |
| Linear issues         | `[agent: linear-expert]`, `[cmd: /linear]`              |
| Documentation         | `[agent: tech-writer]`                                  |
| Code refactoring      | `[agent: refactoring-expert]`                           |
| Running tests         | `[agent: test-runner]`                                  |
| CI failures           | `[skill: ci-troubleshooting]`, `[cmd: /cicheck]`        |
| Code review           | `[cmd: /codereview]`                                    |
| Pre-commit checks     | `[cmd: /precommit]`                                     |
| API/framework docs    | `[skill: dash]`, `[cmd: /dash]`                         |

### Identifying Parallel Tasks

Mark tasks `[parallel]` when they:

- Work on independent files/modules
- Have no shared state or dependencies
- Can be coded/tested in any order

**Example phase with annotations**:

```markdown
## Phase 2: Core Implementation

### 2.1 Data Models [parallel]

- [ ] Create User model [agent: swift-expert] [parallel]
- [ ] Create Recipe model [agent: swift-expert] [parallel]
- [ ] Create Ingredient model [agent: swift-expert] [parallel]
- [ ] Write DQL queries for models [skill: write-dql] [depends: 2.1]

### 2.2 API Layer

- [ ] Implement REST client [agent: rest-expert]
- [ ] Add authentication [agent: swift-expert] [depends: 2.2]

### 2.3 Testing [parallel after 2.1, 2.2]

- [ ] Unit tests for models [agent: test-runner] [parallel]
- [ ] Integration tests for API [agent: test-runner] [parallel]
```

### `/spec implement` Tool Selection

When executing `/spec implement`, check task annotations:

1. If `[skill: X]` present → load skill before executing
2. If `[agent: X]` present → spawn Task with that subagent_type
3. If `[parallel]` present on multiple tasks → can batch via parallel Task calls
4. If no annotation → use general-purpose approach based on file type

## Error Handling

| Situation                  | Action                                                                |
| -------------------------- | --------------------------------------------------------------------- |
| Partial/corrupt spec files | Read what exists, report issues, offer to regenerate missing sections |
| Conflicting requirements   | Add to OPEN_ISSUES.md, ask user to clarify                            |
| Missing `specs/` on update | Offer to create from conversation context                             |
| Large spec files           | Summarize rather than display full content                            |

## Arguments

$ARGUMENTS
