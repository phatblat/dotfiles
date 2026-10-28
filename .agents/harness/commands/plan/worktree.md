---
description: Insert a Phase 0 into a WIP plan that creates a git branch and worktree, switches to it, and moves any WIP work into the new worktree
model: sonnet
allowed-tools: Bash(git:*), Bash(wt:*), Read, Edit, Skill, AskUserQuestion
category: workflow
argument-hint: "[plan-path] [branch] [base-branch]"
---

# Plan Worktree: Add Phase 0 To A WIP Plan

Update a WIP implementation plan (default `PLAN.md` at the repo root) by inserting a **Phase 0: Worktree Setup** that creates a git branch and worktree, switches to it, and moves any WIP work from the current working copy into the new worktree.

## Context Gathering

!`git status --porcelain=v1 2>/dev/null`
!`git branch --show-current 2>/dev/null`

## Parse Arguments

Tokens come from `$ARGUMENTS`:

| Tokens | Meaning |
| --- | --- |
| 0 | plan = `PLAN.md` at repo root; branch derived from plan title slug; base = default branch |
| 1 | plan = token (if it ends in `.md` or names an existing file), else branch = token with plan = `PLAN.md` |
| 2 | plan = token 1; branch = token 2 |
| 3 | plan = token 1; branch = token 2; base = token 3 |
| 4+ | Stop; print `usage: /plan:worktree [plan-path] [branch] [base-branch]` |

## Instructions

Invoke the `plan-worktree` skill and follow it exactly — its Workflow (read plan, assess WIP state, insert Phase 0) is the single source of truth. Do not restate that procedure here; the two must not drift.

## Report

```text
Plan:       <plan path>
Phase 0:    inserted | already present (idempotent no-op)
Branch:     <branch> (base: <base-branch> | existing branch, base unchanged)
WIP:        stash steps live (dirty tree) | conditional (clean tree)
```
