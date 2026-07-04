---
name: pr-approve
description: Approve a GitHub pull request, inferring the target from context when no PR is given. Use when the user invokes `$pr-approve`, asks to approve a PR, or approves a pull request mentioned earlier in the conversation.
---

# pr-approve

Approve a GitHub pull request via `gh pr review --approve`.

## Workflow

### 1. Resolve the target PR

If a PR number, `#1234`, or URL was given directly, strip a leading `#` and use it as the sole candidate — skip inference.

Otherwise, gather candidates from context:

- **Current branch's PR**:
  ```bash
  gh pr view --json number --jq .number 2>/dev/null
  ```
- **Conversation context**: scan the current session for PR references — `#<number>`, `pull/<number>` paths, or full `github.com/.../pull/<number>` URLs mentioned by the user or in prior output.

Deduplicate the results.

- **Zero candidates** → ask directly: "Which PR would you like to approve? (number or URL)"
- **One candidate** → continue to step 2.
- **Multiple candidates** → continue to step 2, fetch metadata for all of them, and let the user choose in step 3.

### 2. Fetch metadata for each candidate

```bash
gh pr view <number> --json number,url,title,state,isDraft,mergedAt,headRefName,baseRefName,author,reviewDecision,reviews,reviewRequests,statusCheckRollup
```

Get the authenticated user's login once:

```bash
gh api user --jq .login
```

Derive per PR:

- **Lifecycle state**: `merged` if `mergedAt` is set, else `closed` if `state == "CLOSED"`, else `open`.
- **My approval status**, in priority order: an existing review from the authenticated login (`approved by you` / `changes requested by you`); else being in `reviewRequests[]` (`waiting on your review`); else `reviewDecision == "APPROVED"` (`approved by others`); else `not requested`.
- **Checks status** from `statusCheckRollup[]`, priority order: any failing conclusion → `failing`; any in-progress/queued status → `running`; any cancelled conclusion → `cancelled`; all success → `passing`; empty rollup → `waiting`.

### 3. Confirm

**Single candidate** — show the card and ask for a yes/no:

```
#<number> <title>
<state> · <my approval status> · <headRefName> → <baseRefName> · @<author> · checks <checks status>
<url>

Approve this PR?
```

**Multiple candidates** — present each as `#<number> <title>` with the same detail line, and ask the user to pick one or more (multi-select). That selection is itself the confirmation — don't ask again.

If the user declines or picks nothing, stop without approving anything.

### 4. Approve

For each confirmed PR:

```bash
gh pr review <number> --approve
```

If `gh` refuses (self-authored PR, already approved, etc.), report that specific failure and continue with the rest.

### 5. Report

```
✅ Approved PR #<number>
<pr_url>
```

Report any failures separately with their reason instead of a ✅ line.
