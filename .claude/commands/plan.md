---
name: plan
description: Read or update PLAN.md for session continuity across Claude conversations
argument_hint: "[read|continue|update|create|clear] [notes]"
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
  - Task
  - Bash
model: sonnet
---

<required_response_format>
Your response MUST begin with this exact text, followed immediately by a Read tool call:

"Reading PLAN.md..."

Then call the Read tool. Do not write anything else before the tool call.
</required_response_format>

<first_tool_call>
Immediately after outputting "Reading PLAN.md...", call:

- Read tool with file_path: "{cwd}/PLAN.md"

If that returns "File does not exist", call:

- Read tool with file_path: "{cwd}/temp/PLAN.md"

Only after completing these Read calls, proceed based on results.
</first_tool_call>

# Plan Management

Manage PLAN.md for session continuity across Claude conversations.

## Response Sequence

1. Output: "Reading PLAN.md..."
2. Call Read tool on `PLAN.md`
3. If not found, call Read tool on `temp/PLAN.md`
4. Then respond based on operation mode and file contents

## Operation Modes

| Argument               | Behavior                                                   |
| ---------------------- | ---------------------------------------------------------- |
| (none) or `read`       | Summarize plan, suggest next steps, wait for direction     |
| `continue`             | Execute pending tasks autonomously until user input needed |
| `update`               | Apply changes based on context or provided notes           |
| `update <notes>`       | Apply specific user-provided notes                         |
| `create <description>` | Create new PLAN.md from description                        |
| `clear`                | Remove PLAN.md                                             |

## After Reading File

**If file exists**, present:

```
**Status:** [status]. **Last:** [recent accomplishment].

**Pending:** [next 2-3 tasks]

**Suggested:** [what to do next]
```

**If file not found** (both Read calls returned "File does not exist"):

```
No PLAN.md found. Use `/plan create <description>` to start one.
```

## Operation Details

### continue

1. Execute pending tasks (delegate to expert agents)
2. Stop when: user decision required, ambiguous requirements, blocker
3. Update PLAN.md after each completed task

### update

Preserve existing structure. Append to sections rather than replacing.

With notes: Incorporate user's notes into appropriate section.
Without notes: Infer from conversation (commits, CI results, blockers).

### create

1. Parse provided description
2. Research if needed (Linear issues, codebase)
3. Create structured PLAN.md
4. Present for review before saving

### clear

After reading confirms file exists, remove it.

## PLAN.md Format

```markdown
# Project: [Name]

**Branch:** `branch-name`
**Status:** [Planning | In Progress | Pushed | Verified]
**Linear Issue:** [link if applicable]

## Objective

[What we're trying to accomplish]

## Tasks

### Phase 1: [Name] ✅/🔄/⏳

- [x] Completed task
- [ ] Pending task

## What Just Happened (YYYY-MM-DD)

[Key accomplishments, decisions made]

## Key Learnings

[Patterns discovered, blockers resolved]
```

## Arguments

$ARGUMENTS
