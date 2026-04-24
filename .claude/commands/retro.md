---
name: retrospective
description: Perform autonomous agent configuration improvement.
argument_hint: <friction points from recent sessions>
model: sonnet
allowed_tools:
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - TaskOutput
  - TaskCreate
  - TaskGet
  - TaskUpdate
  - TaskList
---

<default_to_action>
Apply fixes directly. Read each file before editing. Present a summary of all changes at the end.
</default_to_action>

<use_parallel_tool_calls>
Read and analyze files in parallel batches. Group independent edits together.
</use_parallel_tool_calls>

# Retrospective: Agent Configuration Improvement

Analyze recent session friction and apply targeted fixes to `~/.claude/` config files.

## Input

The user provides friction points from recent sessions via `$ARGUMENTS`. These describe problems like:
- Sub-agents failing due to missing `allowed_tools`
- Mandatory delegation being skipped
- Commands not enforcing tool usage
- YAML formatting issues (camelCase vs snake_case)
- Instructions contradicting CLAUDE.md

If no arguments are provided, ask the user to describe 2-5 friction points from recent sessions.

## Workflow

### 1. Load Reference Context
Read these files once for baseline rules:
- `~/.claude/CLAUDE.md` — master rules to check against

### 2. Analyze Friction Points
For each friction point from `$ARGUMENTS`:
1. Identify the root cause (missing tool, wrong rule, stale reference, etc.)
2. Map it to the specific config file(s) that need changes
3. Categorize:
   - **Missing `allowed_tools`** — sub-agent couldn't use a needed tool
   - **Missing delegation rule** — work was done directly instead of delegated
   - **Broken reference** — agent/skill/command references something that doesn't exist
   - **YAML formatting** — camelCase keys, missing frontmatter, duplicate keys
   - **Contradicting CLAUDE.md** — instruction conflicts with master rules
   - **Missing instruction** — a rule that should exist but doesn't

### 3. Create Fix Plan
Use TaskCreate to build a checklist of fixes. Each task should specify:
- The file to modify
- What to change
- What friction it prevents

### 4. Apply Fixes
For each planned fix:
1. Read the target file
2. Apply the edit
3. Mark the task complete

Guard rails:
- Only modify files under `~/.claude/` (agents, commands, skills, CLAUDE.md)
- Preserve existing functionality — add/fix, don't remove working config
- Validate YAML frontmatter after editing (starts with `---`, has `name:`, single `description:`, no duplicate keys)
- Use snake_case for all YAML keys

### 5. Validate
After all edits, verify each modified file:
- Frontmatter parses correctly (check `---` delimiters, required fields)
- No broken references introduced
- Changes align with CLAUDE.md rules

### 6. Report

```
# Retrospective Report

## Friction Points Analyzed
1. [friction point] → root cause → fix applied

## Changes Made
| File          | Change                        | Prevents                              |
| ------------- | ----------------------------- | ------------------------------------- |
| agents/foo.md | Added `Bash` to allowed_tools | Sub-agent build failures              |
| CLAUDE.md     | Added delegation rule for X   | Direct handling instead of delegation |

## Validation
- All modified files have valid frontmatter
- No broken references
- All changes consistent with CLAUDE.md
```

## User's Friction Points

$ARGUMENTS
