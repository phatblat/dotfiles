---
description: Investigate and fix failing CI jobs until checks pass
model: sonnet
argument_hint: "<PR-ref, CI run URL(s), or description of the failures>"
allowed-tools:
  - Bash(gh:*)
  - Bash(git:*)
  - Bash(grep:*)
  - Read
  - Edit
  - Write
  - AskUserQuestion
  - Skill
category: workflow
---

# Fix CI

Investigate and fix failing CI. Invoke the `ci-fix` skill, then apply it to:

`$ARGUMENTS`

If no arguments provided, detect the current branch's PR:

```bash
gh pr view --json url --jq '.url'
```

Then triage that PR's failing checks.
