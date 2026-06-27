---
name: pr-resolve-feedback
description: Address GitHub PR review comments by fetching, evaluating, fixing, committing, and resolving feedback. Use when invoked as `$pr-resolve-feedback` or when the user asks to resolve PR feedback.
---

# pr-resolve-feedback

Address GitHub PR review feedback.

## Workflow

Use the existing `resolve-feedback` skill for the detailed implementation workflow.

If the user provided a PR URL or comment URL, pass that target through to `resolve-feedback`.

If no target is provided, detect the current branch's PR first:

```bash
gh pr view --json url --jq '.url'
```

Then process unresolved comments for that PR.
