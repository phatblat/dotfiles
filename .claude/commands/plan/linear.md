---
name: linear
description: Start work on a Linear ticket — plan, branch, implement, test, PR
argument_hint: "<TICKET-ID> [--base <branch>] — e.g., DEVX-696, DEVX-42 --base release/4.15"
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - TaskCreate
  - TaskUpdate
  - TaskGet
  - TaskList
  - mcp__linear__get_issue
  - mcp__linear__list_comments
  - mcp__linear__save_comment
  - mcp__linear__save_issue
  - mcp__linear__list_issue_labels
  - mcp__linear__list_issue_statuses
  - mcp__linear__get_team
---

<default_to_action>
If no ticket ID is provided, ask the user for one. The default team prefix is DEVX.
If the user provides just a number (e.g., "696"), prepend "DEVX-" to form the full identifier.
</default_to_action>

<track_progress_with_todos>
Use TaskCreate to track workflow phases. Create tasks for each major phase:

1. Gather context
2. Create plan
3. Create branch (after plan approval)
4. Post plan to Linear
5. Implement changes
6. Push & open draft PR
7. Run tests
8. Update Linear with results
   Use TaskUpdate to mark tasks complete as you proceed.
   </track_progress_with_todos>

<continuous_execution>
After plan approval, execute continuously until blocked or complete.
Stopping conditions: test failure needing user input, ambiguous requirement, external dependency.
</continuous_execution>

# Linear Ticket Workflow

Start work on a Linear ticket end-to-end: gather context, plan, branch, implement, test, and open a draft PR.

## Arguments

`$ARGUMENTS`

Parse arguments:

- **Ticket ID** (required): Full identifier like `DEVX-696` or just a number (auto-prefixed with `DEVX-`).
- **`--base <branch>`** (optional): Base branch to create the topic branch from. Defaults to `main`.

## Phase 1: Gather Context

### 1.1 Fetch ticket details

Use `mcp__linear__get_issue` to retrieve the ticket. Extract:

- **Title**
- **Description** (full markdown)
- **Labels** (note K-\*, A-\*, S-\*, P-\* labels — these inform PR labeling later)
- **Priority**
- **Assignee**
- **State**

### 1.2 Fetch conversation threads

Use `mcp__linear__list_comments` to read all comment threads on the ticket. These often contain clarifying context, decisions, and requirements not in the description.

### 1.3 Derive branch name

From the ticket title, generate a descriptive kebab-case slug:

- Strip special characters, lowercase everything
- Keep it concise (3-5 words max)
- Format: `ben/<ticket-id-lowercase>/<slug>`
- Example: ticket DEVX-696 "Fix Bluetooth reconnection on Android" → `ben/devx-696/fix-bluetooth-reconnection-android`

### 1.4 Assign ticket to me

Use `mcp__linear__save_issue` to:

- Set assignee to "me"
- Set state to "In Progress"

## Phase 2: Create Plan

### 2.1 Analyze the codebase

Based on the ticket description and comments, identify:

- Which files/modules need changes
- Existing patterns to follow
- Dependencies and integration points

Use `Glob`, `Grep`, and `Read` tools to explore the codebase. For complex exploration, use an `Agent` with `subagent_type=Explore`.

### 2.2 Draft plans with diverse agents

Launch 2-3 `Agent` instances **in parallel**, each producing an independent plan that optimizes for a different concern. Every agent receives the same context (ticket details, comments, codebase findings from 2.1) but a different **optimization lens**.

**Choosing lenses:** Pick 2-3 dimensions that create meaningful trade-offs for _this specific ticket_. Do not reuse the same set every time — select dimensions that surface real alternatives given the nature of the change.

Example dimensions (pick what fits, invent others as needed):

- Minimal diff / surgical change
- Long-term maintainability / structural improvement
- Performance / efficiency
- Testability / observability
- API ergonomics / developer experience
- Backward compatibility / migration safety
- Incremental delivery (shippable in stages)

**Agent prompt structure:** Each agent should receive:

- The ticket title, description, and comment context
- The codebase analysis from 2.1 (relevant files, patterns, integration points)
- Its assigned optimization lens and a one-sentence framing of what "good" means through that lens
- The plan template below
- Instructions to use `Read`, `Grep`, and `Glob` to verify assumptions about the codebase

**Plan template** (each agent produces one):

```markdown
## Plan <LETTER>: <Short Label> — <TICKET-ID>

**Optimizes for:** <lens in 3-5 words>

### Summary

<1-2 sentence description of the approach and why it makes the trade-offs it does>

### Changes

1. <File/module> — <what changes and why>
2. ...

### Test Plan

- [ ] <Specific test step that can be validated>
- [ ] ...

### Trade-offs

- **Gains:** <what this approach does well>
- **Costs:** <what it sacrifices or defers>

### Risks & Open Questions

- <Any concerns or ambiguities>
```

**Determining test plan steps:**

- Check for `justfile` → use relevant `just build*`, `just test*`, `just lint*`, `just format*` recipes
- Check for root `Makefile` (ditto monorepo) → use `make build-*`, `make test-*`, `make lint-*`, `make format-*` targets
- Include compilation/type-check steps
- Include any relevant integration or E2E tests
- Include manual verification steps where automated tests don't cover

### 2.3 Present plans and get selection

Display all plans side-by-side with a brief **comparison summary** highlighting the key trade-off between them. Then ask:

> Here are the plans. You can:
>
> 1. Pick one as-is (e.g., "go with Plan B")
> 2. Combine elements (e.g., "Plan A's approach but with Plan C's test strategy")
> 3. Request a new angle if none fit
>
> Which direction?

**STOP HERE and wait for user response. Do not proceed until the user selects or synthesizes a plan.**

If the user combines elements, synthesize a final plan that merges the requested pieces into a coherent whole before proceeding.

## Phase 3: Create Branch

After the user approves a plan, create the topic branch before posting or implementing.

```bash
git fetch origin
git checkout -b <branch-name> origin/<base-branch> --no-track
```

**IMPORTANT:** Use `--no-track` to avoid setting the topic branch to track the base branch (e.g., `main`). Tracking will be set up when pushing in Phase 6.

If the base branch doesn't exist on remote, error and ask the user.

## Phase 4: Post Plan to Linear

Post the **selected plan** (or synthesized hybrid) as a **new comment** on the Linear ticket using `mcp__linear__save_comment`:

- `issueId`: the ticket identifier (e.g., `DEVX-696`)
- `body`: the final plan in markdown (include its label and optimization lens for traceability)

Save the returned comment ID — all plan updates go to this thread using `parentId`.

## Phase 5: Implement Changes

### 5.1 Determine implementation strategy

Based on the selected plan's complexity:

- **Simple (1-3 files, single concern)**: Implement directly
- **Medium (4-8 files, related changes)**: Implement directly with logical commit grouping
- **Complex (8+ files, multiple independent concerns)**: Spawn parallel `Agent` workers

For parallel agents:

1. Implement shared dependencies first (types, interfaces, core utilities)
2. Spawn agents for independent work streams with clear boundaries
3. Each agent gets: files to read for patterns, target files to modify, conventions to follow

### 5.2 Commit in logical groups

Group related changes into cohesive commits using conventional commit format:

- `feat(scope): description` for new features
- `fix(scope): description` for bug fixes
- `refactor(scope): description` for refactoring
- `test(scope): description` for test additions
- `docs(scope): description` for documentation
- `chore(scope): description` for maintenance

Each commit message should reference the ticket: `Resolves DEVX-696` or `Part of DEVX-696` (always UPPERCASE in commits/PR).

## Phase 6: Push & Open Draft PR

### 6.1 Push topic branch

```bash
git push -u origin <branch-name>
```

This pushes the topic branch to the remote and sets up tracking between the local and remote copies of the same branch (via `-u`). Never push directly to the base branch.

### 6.2 Determine PR labels

Always include:

- `D-skip-changelog`

Select from the ticket's existing labels, plus infer from the changes:

**Kind (K-\*) — at least one required:**
| Label | When to use |
|-------|------------|
| `K-bug` | Fixing broken behavior |
| `K-feature` | New functionality |
| `K-improvement` | Enhancing existing behavior |
| `K-chore` | Non-production maintenance |
| `K-debt-repayment` | Cleaning up tech debt |
| `K-documentation` | Documentation only |
| `K-testing` | Test additions/improvements |
| `K-removal` | Removing code/features |
| `K-perf` | Performance work |

**Area (A-\*) — at least one required:**
Infer from files changed. Common areas:
`A-sdks`, `A-tools`, `A-ci-cd`, `A-tests`, `A-documentation`, `A-core-library`,
`A-security`, `A-cloud-services`, `A-networking`, `A-replication`, `A-ffi`,
`A-transports`, `A-observability`, `A-query`, `A-portal`, `A-operations`,
`A-developer-experience`, `A-project-structure`, `A-auth`, `A-api`, `A-utilities`

**SDK (S-\*) — if SDK work:**
`S-cocoa`, `S-kotlin`, `S-js`, `S-react-native`, `S-python`, `S-rust`,
`S-wasm`, `S-go`, `S-java`, `S-flutter`, `S-dotnet`, `S-cpp`

**Platform (P-\*) — if platform-specific:**
`P-ios`, `P-android`, `P-macos`, `P-linux`, `P-windows`, `P-web`,
`P-tvos`, `P-watchos`, `P-visionos`, `P-aaos`

### 6.3 Create draft PR

```bash
gh pr create --draft \
  --title "<conventional-prefix>(<scope>): <short description>" \
  --assignee phatblat \
  --label "D-skip-changelog,<K-label>,<A-label>,<additional-labels>" \
  --body "$(cat <<'EOF'
Resolves [DEVX-NNN](https://linear.app/ditto/issue/DEVX-NNN)

## Summary

<1-3 bullet points describing the changes>

## Test Plan

- [ ] <test step from plan>
- [ ] <test step from plan>
- [ ] ...

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**IMPORTANT:** Always use UPPERCASE ticket IDs in PR title, description, and commit messages (e.g., `DEVX-696`).

## Phase 7: Execute Test Plan

Run each test step from the plan that can be validated locally:

1. **Build**: Run build commands and verify success
2. **Lint**: Run linting and fix any issues (commit fixes separately)
3. **Format**: Run formatters and commit any changes
4. **Unit tests**: Run test suites
5. **Integration tests**: Run if available and applicable

For each step, record: pass/fail, output summary, any issues found.

If tests fail:

1. Analyze the failure
2. Fix if straightforward
3. Commit the fix
4. Re-run the test
5. If complex, report to user and pause

## Phase 8: Update Linear

### 8.1 Post test results

Reply to the plan comment thread (using `parentId` from Phase 4) with test results:

```markdown
## Test Results

| Step  | Status  | Notes          |
| ----- | ------- | -------------- |
| Build | ✅ Pass | ...            |
| Lint  | ✅ Pass | ...            |
| Tests | ✅ Pass | X tests passed |

### PR

<link to draft PR>
```

### 8.2 Update PR description

Check off completed test plan items in the PR description using `gh pr edit`.

### 8.3 Final status

Report to user:

- PR link
- Test results summary
- Any items needing manual review
- Remind: "PR is in draft — mark ready for review when you're satisfied."
