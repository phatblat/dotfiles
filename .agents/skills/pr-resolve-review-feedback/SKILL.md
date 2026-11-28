---
name: pr-resolve-review-feedback
description: Use when invoked as `$pr-resolve-review-feedback` or when the user asks to resolve PR feedback; fetches, fixes, commits, and resolves line, file, and PR-level comments.
disable-model-invocation: true
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

Also scan already-resolved threads for follow-up comments left after the resolution (for example a bot re-review of an earlier commit), and reply to each with either an acknowledgement or a fix; `resolve-review-feedback` defines the procedure.
