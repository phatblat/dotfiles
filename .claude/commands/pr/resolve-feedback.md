---
description: Address GitHub PR review comments — fetch, evaluate, fix, commit, and resolve
model: sonnet
argument_hint: "<PR-URL or comment-URL>"
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

# Resolve PR Feedback

Address GitHub PR review comments. Invoke the `resolve-feedback` skill, then apply it to:

`$ARGUMENTS`

If no arguments provided, detect the current branch's PR:

```bash
gh pr view --json url --jq '.url'
```

Then process that PR's unresolved comments.
