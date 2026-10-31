---
name: write-plan
description: "Discuss a feature, draft an implementation plan, and review it through isolated passes"
argument-hint: "<optional-path-to-requirements-or-spec>"
disable-model-invocation: true
---

<!-- Adapted from mkrtchian/spec-driven-dev v1.11.0 (https://github.com/mkrtchian/spec-driven-dev), MIT License, Copyright (c) 2026 Roman Mkrtchian. See LICENSE in this directory. -->

## Host notes

This workflow runs on every host in the shared agent harness (Claude Code, OMP, Codex, OpenCode, Cursor, Grok, Antigravity).

- `$ARGUMENTS` is the text the user passed when invoking this skill. Treat it as empty when nothing was passed.
- Each `Dispatch(...)` block below starts one fresh subagent that runs the named specialist (`agent=`), with `prompt` as its entire task and `description` as its label. Wait for it to finish and act only on its final report. Map the block to the host's subagent tool:
  - Claude Code: the subagent tool (`Task`/`Agent`) with `subagent_type` set to the `agent` value and `model="opus"`.
  - OMP: the `task` tool with one task item whose `agent` is the `agent` value and whose `task` text is the `prompt`.
  - Codex and other hosts with named custom agents: spawn the custom agent with that name.
  - A host without named agents: spawn a general-purpose subagent whose prompt begins "Read `~/.agents/harness/agents/<agent>.toml` and follow its `developer_instructions` as your complete role.", followed by the `prompt` text.
- `model="opus"` asks for the strongest available model. On a host that cannot choose a model per dispatch, use the session's model.
- When this skill says to ask the user, use the host's question tool if it has one (`AskUserQuestion` in Claude Code, `ask` in OMP). Otherwise ask in chat and wait for the answer.

## Objective

Guide the user from an idea or spec to a reviewed, step-by-step implementation plan ready for the `implement-plan` skill.

The process has two modes: interactive discussion (you talk to the user), and isolated review passes (fresh sub-agents each handle one concern).

## Phase 1: Discussion (interactive)

If `$ARGUMENTS` is provided, read it as requirements context (spec, user stories, discovery notes, or a rough plan).

### Explore the codebase

1. Identify which areas of the codebase are relevant to the user's idea. Read key source files to understand current patterns, types, and architecture.
2. Check for nested `AGENTS.md` or `CLAUDE.md` files in relevant directories.

### Clarify with the user

Ask questions to narrow the scope. Focus on:

- **What**: What exactly should the feature/change do? What are the acceptance criteria?
- **Where**: Which parts of the codebase are affected? Are there existing patterns to follow?
- **How**: What technical approach? Are there trade-offs to decide?
- **Boundaries**: What should NOT change? What's out of scope?
- **Testing**: What scenarios need test coverage?

Keep asking until you have enough to write a precise plan. The user signals readiness by saying something like "OK", "let's go", "write it", "that's enough", etc.

## Phase 2: Draft the plan

Write the plan to `plans/YYYY-MM-DD_slug.md` where:
- `YYYY-MM-DD` is today's date
- `slug` is a short kebab-case name derived from the feature (e.g., `user-auth`, `api-pagination`)

Create the `plans/` directory if it doesn't exist.

The plan should cover:

- **Context**: What problem this solves, why this approach
- **Approach**: High-level strategy
- **Files to modify**: Exact paths, what changes in each
- **Code details**: Type signatures, method signatures, key logic
- **What stays unchanged**: Explicitly list what should NOT be touched
- **Edge cases**: Scenarios and expected behavior
- **Test scenarios**: What to test, with expected inputs/outputs
- **Verification**: Commands to run to confirm correctness

That list is a set of concerns, not a section layout: cover them in whatever shape fits the change. One formatting rule: unless the project documents a wrapping convention of its own, write each paragraph as a single line, without hard wrapping. A wrapped paragraph reflows when one word changes, so a one-word correction shows up as ten changed lines in the diff, and the plan is meant to be reviewed in a pull request like any other file.

Tell the user the plan path when done. From this point on, `$PLAN_PATH` refers to the path of the plan file you just created.

## Phase 3: Plan review (fresh sub-agent)

Display:
```
--- Pass 1: Plan Review ---
Checking for gaps, wrong assumptions, and integration risks...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-plan-reviewer",
  model="opus",
  description="Review plan for gaps",
  prompt="
    Plan to review: $PLAN_PATH
  "
)
```

Report what was found/fixed to the user.

## Phase 4: Plan standards (fresh sub-agent)

Display:
```
--- Pass 2: Plan Standards ---
Checking plan against project coding and testing standards...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-plan-standards",
  model="opus",
  description="Check plan standards",
  prompt="
    Plan to review: $PLAN_PATH
  "
)
```

Report what was found/fixed to the user.

## Phase 5: Due diligence (fresh sub-agent)

Display:
```
--- Pass 3: Due Diligence ---
Web-verifying external facts and surfacing decisions that need your judgment...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-plan-diligence",
  model="opus",
  description="Due-diligence pass",
  prompt="
    Plan to vet: $PLAN_PATH
  "
)
```

Present both buckets (`### FIXED` and `### REQUIRES YOUR JUDGMENT`) to the user verbatim: never drop, merge, or reword a finding. You may append a short annotation to an individual item that was already settled during the discussion (e.g. "already decided in discussion: you accepted this risk with mitigation X"), since you alone hold the discussion context and the isolated agent cannot know what the user already chose. The agent's original text always stays visible above your annotation. Show `REQUIRES YOUR JUDGMENT` prominently.

## Phase 6: Step breakdown (fresh sub-agent)

Display:
```
--- Pass 4: Step Breakdown ---
Splitting plan into implementation steps...
```

Spawn a sub-agent:

```
Dispatch(
  agent="sdd-step-breakdown",
  model="opus",
  description="Break plan into steps",
  prompt="
    Plan to process: $PLAN_PATH
  "
)
```

Handle the breakdown's output:

- **STEPS ADDED**: report the step summary to the user and proceed to Phase 7.
- **PLAN TOO AMBIGUOUS TO BREAK DOWN**: surface what is unclear and what the plan must resolve, and stop before the Phase 7 "Plan Ready" summary. The plan has no steps yet, so it is not ready for the `implement-plan` skill.

## Phase 7: Done

Display:

```
--- Plan Ready ---

Plan: $PLAN_PATH
Steps: N total

Review the plan and adjust as needed (manually or with my help).
When ready, run the implement-plan skill on: $PLAN_PATH
```

Then:

1. **Re-surface `REQUIRES YOUR JUDGMENT`**: repeat the diligence agent's `REQUIRES YOUR JUDGMENT` items as the things to resolve before implementing. If that bucket was empty, say so.
2. **Propose committing the plan (never do it automatically)**: ask the user whether to commit the plan now, so it exists in git before the `implement-plan` skill.
   - On **yes**: discover the project's commit convention using the same priority order the committing agents use (see `~/.agents/harness/agents/sdd-standards-enforcer.toml`, "Discover commit conventions"): project instruction-file rules first, then a commit skill or command, then commitlint/commitizen config. Stage ONLY the plan file (never `git add -A` or `git add .`) and commit following that convention, and never use `git commit --no-verify`: pre-commit hooks must run. If nothing more specific is discovered, fall back to `docs(plans): add <slug>`.
   - On **no**: leave the plan uncommitted. the `implement-plan` skill still works on the uncommitted file.

## References

- `~/.agents/skills/implement-plan/references/workflow.md`: upstream workflow guide, including failure paths and how to resume an interrupted run.
- `~/.agents/skills/implement-plan/references/design-decisions.md`: upstream rationale for the isolated passes.
