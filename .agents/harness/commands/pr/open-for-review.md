---
description: Mark the current branch's draft PR as ready for review
model: sonnet
allowed-tools: Bash(git:*), Bash(gh:*)
category: workflow
---

# Open PR for Review

Take the current branch's PR out of draft mode and mark it ready for review.

## Instructions

### 1. Find the PR

```bash
gh pr view --json number,url,title,isDraft \
  --jq '"\(.number)|\(.isDraft)|\(.title)|\(.url)"'
```

If no PR exists for the current branch, stop and report: "No open PR found for branch `$(git branch --show-current)`."

### 2. Check Draft State

- If `isDraft` is `false`, report that the PR is already open for review and stop.
- If `isDraft` is `true`, proceed.

### 3. Mark Ready

```bash
gh pr ready <number>
```

### 4. Report Result

```
✅ PR #<number> is now ready for review
<pr_url>
```

## Notes

To reverse — convert a ready PR back to draft — run `gh pr ready <number> --undo`.
