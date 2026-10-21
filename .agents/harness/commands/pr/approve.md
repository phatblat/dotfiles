---
description: Approve a GitHub PR, inferring the target from context when not given
model: sonnet
argument-hint: "[<PR number, #1234, or URL>]"
allowed-tools: Bash(gh:*), Bash(git:*), AskUserQuestion
category: workflow
---

# Approve PR

Approve a GitHub pull request via `gh pr review --approve`.

## Instructions

### 1. Resolve the target PR

If `$ARGUMENTS` is given (a bare number, `#1234`, or a full PR URL), strip a leading `#` and use it directly as the candidate — skip inference.

Otherwise, gather candidates from context:

- **Current branch's PR**:
  ```bash
  gh pr view --json number --jq .number 2>/dev/null
  ```
- **Conversation context**: scan the current session for PR references — `#<number>`, `pull/<number>` paths, or full `github.com/.../pull/<number>` URLs mentioned by the user or in prior tool output.

Deduplicate the results.

- **Zero candidates** → ask the user directly (plain question): "Which PR would you like to approve? (number or URL)"
- **One candidate** → proceed to step 2 with it.
- **Multiple candidates** → proceed to step 2, fetch metadata for all of them, and let the user pick via the multi-select in step 3.

### 2. Fetch metadata for each candidate

For each candidate PR number:

```bash
gh pr view <number> --json number,url,title,state,isDraft,mergedAt,headRefName,baseRefName,author,reviewDecision,reviews,reviewRequests,statusCheckRollup
```

Get the authenticated user's login once (for the "my approval" fields):

```bash
gh api user --jq .login
```

Derive per PR:

- **Lifecycle state**: `merged` if `mergedAt` is set, else `closed` if `state == "CLOSED"`, else `open`.
- **My approval status** (check in this order):
  1. If `reviews[]` contains an entry from the authenticated login → `approved by you` / `changes requested by you` (use that review's latest state).
  2. Else if `reviewRequests[]` includes the authenticated login → `waiting on your review`.
  3. Else if `reviewDecision == "APPROVED"` → `approved by others`.
  4. Else → `not requested`.
- **Checks status** from `statusCheckRollup[]`, priority order: any `FAILURE`/`ERROR` conclusion → `failing`; else any `IN_PROGRESS`/`QUEUED` status → `running`; else any `CANCELLED` conclusion → `cancelled`; else all `SUCCESS` → `passing`; else (empty rollup) → `waiting`.

### 3. Confirm with the user

**Single candidate** — show the card and confirm with a yes/no AskUserQuestion:

```
#<number> <title>
<state> · <my approval status> · <headRefName> → <baseRefName> · @<author> · checks <checks status>
<url>

Approve this PR?
```

**Multiple candidates** — use AskUserQuestion with `multiSelect: true`, one option per PR:

- `label`: `"#<number> <title>"` (truncate title if needed to keep it scannable)
- `description`: `"<state> · <my approval status> · <headRefName> → <baseRefName> · @<author> · checks <checks status> · <url>"`

The header should be short, e.g. `"Approve PR"`. Selecting one or more options in this step doubles as confirmation — do not ask again after this.

If the user declines or selects nothing, stop without approving anything.

### 4. Approve

For each confirmed PR number:

```bash
gh pr review <number> --approve
```

If `gh` reports the PR can't be approved (e.g. self-authored — GitHub disallows approving your own PR, or already approved), report that specific failure and continue with the rest.

### 5. Report

```
✅ Approved PR #<number>
<pr_url>
```

For any PR that failed, report it separately with the reason instead of a ✅ line.
