---
name: pr-resolve-review-feedback
description: Address GitHub PR review comments at line, file, and PR level by fetching, evaluating, fixing, committing, and resolving feedback. Use when invoked as `$pr-resolve-review-feedback` or when the user asks to resolve PR feedback.
---

# pr-resolve-review-feedback

Address GitHub PR review feedback.

## Workflow

Use the existing `resolve-review-feedback` skill for the detailed implementation workflow.

If the user provided a PR URL or comment URL, pass that target through to `resolve-review-feedback`.

If no target is provided, detect the current branch's PR first:

```bash
gh pr view --json url --jq '.url'
```

Then process unresolved comments for that PR.
