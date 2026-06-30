---
name: gha-checks
description: |-
  Check GitHub Actions CI status for PRs and branches. Use when the user asks
  "did CI pass", "check status", "what failed", "are checks green", "PR checks",
  "CI status", "workflow status", "re-run jobs", or wants a quick summary of
  GitHub Actions runs for a PR or the current branch.
---

# GHA Checks

Quickly check GitHub Actions CI status for a PR or branch, summarize results, and triage failures.

## When to Use

- User asks about CI/check status on a PR or branch
- User wants to know if checks passed before merging
- User asks to re-run failed jobs
- After pushing, to confirm CI is green

## Process

### Step 1: Resolve the Target

Determine what to check:

- **PR number given** (e.g., "checks on #319"): use that directly
- **PR URL given**: extract owner/repo and PR number
- **Run URL given** (e.g., `github.com/.../actions/runs/123`): use `/gha-log-reader` instead — it's built for run-level diagnosis
- **No PR specified**: find the PR for the current branch:
  ```bash
  gh pr view --json number,url,headRefName --jq '"\(.number)|\(.url)|\(.headRefName)"'
  ```
- **No PR exists**: fall back to listing runs for the branch:
  ```bash
  branch=$(git branch --show-current)
  gh run list --branch "$branch" --limit 5 --json databaseId,status,conclusion,name,createdAt,headBranch \
    --jq '.[] | "\(.databaseId)|\(.name)|\(.status)|\(.conclusion // "—")|\(.createdAt)"'
  ```

### Step 2: Get Check Status

For a PR:

```bash
gh pr checks <number> --json name,state,description,detailsUrl,completedAt \
  --jq '.[] | "\(.name)|\(.state)|\(.description // "")|\(.detailsUrl)"'
```

### Step 3: Summarize

Present a concise summary:

```
## PR #<number> Checks

✅ 3 passed | ❌ 1 failed | ⏳ 1 pending

| Check | Status | Details |
|-------|--------|---------|
| build | ✅ pass | — |
| lint  | ✅ pass | — |
| test  | ❌ fail | Node 20 — exit code 1 |
| deploy | ⏳ pending | Waiting on test |
```

Rules:
- Show all checks, not just failures
- Sort: failed first, then pending, then passed
- Include the description field when available (often has the failure hint)
- Keep it scannable — one line per check

### Step 4: Triage Failures

For each failed check:

1. Get the run ID:
   ```bash
   gh pr checks <number> --json name,state,detailsUrl \
     --jq '.[] | select(.state == "FAILURE") | "\(.name)|\(.detailsUrl)"'
   ```

2. Extract the run ID from the URL (format: `.../actions/runs/<id>/...`)

3. Get the failed step and tail of its log:
   ```bash
   gh run view <run-id> --json jobs \
     --jq '.jobs[] | select(.conclusion == "failure") | "\(.name): step \(.steps[] | select(.conclusion == "failure") | .name)"'
   ```

4. Pull the last 50 lines of the failed job's log:
   ```bash
   gh run view <run-id> --log-failed 2>/dev/null | tail -50
   ```

5. Present a brief diagnosis:
   ```
   ### ❌ test (run 12345678)
   Failed step: Run tests
   
   <last few relevant log lines>
   
   Likely cause: <one-sentence assessment>
   ```

### Step 5: Offer Next Actions

Based on the results:

- **All green**: "All checks passed. Ready to merge."
- **Failures**: Offer:
  - "Want me to dig deeper into the `<name>` failure?" → invoke `/gha-log-reader` with the run URL
  - "Want me to re-run the failed jobs?" → `gh run rerun <run-id> --failed`
- **Pending**: "Checks still running. Want me to check again in a few minutes?" → suggest `/loop`
- **No checks**: "No checks configured for this PR/branch."

## Re-running Jobs

When the user asks to re-run:

```bash
# Re-run only failed jobs (cheaper, faster)
gh run rerun <run-id> --failed

# Re-run all jobs in the run
gh run rerun <run-id>
```

Always prefer `--failed` unless the user explicitly asks to re-run everything.

## Integration

- **Escalate to `/gha-log-reader`** for deep log analysis when the tail snippet isn't enough
- **Pairs with `/git:push`** — check status after pushing
- **Pairs with `pr-style`** — confirm checks before marking ready for review

## Do NOT

- Parse full logs inline — that's `/gha-log-reader`'s job
- Re-run jobs without asking the user first
- Assume a failed check is the user's fault — it could be infra, flaky tests, or upstream
