---
name: gha-log-reader
version: 0.2
description: >
  Diagnoses failing GitHub Actions runs by reading logs, identifying the root cause,
  and suggesting fixes. Use this skill whenever a user shares a GHA run URL, pastes
  runner log output, mentions a failing workflow, asks why a CI job is broken, or
  says anything like "my GHA is failing", "workflow failed", "can you check my run",
  or "CI is broken". Also trigger when raw log text is detected in the conversation
  that appears to come from a GitHub Actions runner. Do NOT use for general GHA
  workflow authoring questions, YAML formatting help, or passing runs with no failure
  context.
compatibility:
  gh_cli: required (graceful degradation to paste if unavailable)
---

# GHA Log Reader

Diagnose failing GitHub Actions runs: find the root cause, confirm it with the user,
then suggest actionable fixes — respecting what the user can actually do given their
GitHub permissions.

## Reference Files (read on demand only)

- `references/ditto-ci.md` — Ditto CI architecture, runner fleet, known flaky jobs,
  cache system, CI labels, path filtering. **Read this as soon as Phase 0 confirms
  the repo is `getditto/ditto`.** Do not read it for other repos.
- `references/preflight-recovery.md` — full recovery dialogs for missing `gh`,
  unauthenticated `gh`, 403/404 access errors, and missing `jq`. **Read only when a
  pre-flight check fails.**

---

## gh CLI — Read-Only Rules

**ALL log access goes through the `gh` CLI. No exceptions.**

### Allowed commands (reads only)

```bash
gh run view <run-id> --repo <owner/repo>                              # run summary
gh job view <job-id> --repo <owner/repo>                              # single job summary
gh api "repos/<owner/repo>/actions/runs/<run-id>/jobs?per_page=100"   # list jobs, page 1
gh api "repos/<owner/repo>/actions/runs/<run-id>/jobs?per_page=100&page=N"  # subsequent pages
gh api repos/<owner/repo>/actions/jobs/<job-id>                       # job detail + steps
gh api repos/<owner/repo>/actions/jobs/<job-id>/logs                  # raw log for one job
```

### Blocked — never run these

Any `gh` command that writes, modifies, or triggers is **strictly off-limits**:
`gh run re-run|cancel|delete`, `gh run view --log-failed` (unreliable on large runs),
`gh workflow run|enable|disable`, `gh repo *`, `gh pr *`, `gh issue *`, `gh secret *`,
`gh variable *`, `gh api --method POST/PUT/PATCH/DELETE *`.

If a command is not in the **Allowed** list above, do not run it.

---

## Parsing a Run URL

Given `https://github.com/owner/repo/actions/runs/RUN_ID/job/JOB_ID`, extract:
- `owner/repo` → e.g. `getditto/ditto`
- `RUN_ID` → e.g. `26281110875`
- `JOB_ID` (optional, may point directly to a failing job)

---

## Pre-flight — Dependency Checks (always run before anything else)

```bash
gh --version && gh auth status && jq --version
```

If all three succeed, proceed to Phase 0. **If any check fails**, read
`references/preflight-recovery.md` and follow the recovery path for that check —
do not proceed past a hard failure until it is resolved or the user has accepted
a fallback (paste mode for missing/unauthenticated `gh`; user-approved `python3`
fallback for missing `jq`).

---

## Phase 0 — Job Triage (always run first)

Large runs can have 100+ jobs across multiple pages. Never fetch logs until you know
exactly which job failed.

### Step 0: Confirm the repo

```bash
gh run view <RUN_ID> --repo <owner/repo>
```

Check the repo field. **If it is `getditto/ditto`, read `references/ditto-ci.md`
now** — it identifies rollup jobs, known flaky jobs, and runner context needed below.
For any other repo, use that file only if its patterns clearly apply.

### Step 1: Fetch all jobs with pagination

```bash
gh api "repos/<owner/repo>/actions/runs/<RUN_ID>/jobs?per_page=100"
```

Check `total_count`. If > 100, fetch additional pages
(`&page=N`, ceil(total_count / 100) pages total).

### Step 2: Filter to real failures

Keep only jobs with `conclusion: "failure"`, then **exclude rollup/summary jobs** —
these fail because a child job failed, not because they did real work. A job is a
rollup if:
- Its only failing step is an aggregation step ("Job Checks", "Check results",
  "Check domain results"), not a build/test step
- Its name ends in `-workflow`, `-gate`, or `-ci` and has no build/test steps

### Step 3: Present failing jobs to user

If there is only one real failing job, proceed directly to Phase 0.5 without asking.
If multiple, present a numbered list with job IDs and ask the user to pick one
(or "all" to investigate sequentially).

---

## Phase 0.5 — Step Selection

Fetch step-level detail for the target job:

```bash
gh api repos/<owner/repo>/actions/jobs/<JOB_ID>
```

Filter the `steps` array to `conclusion: "failure"` and display job name, runner,
and failing step(s). If multiple failing steps, ask which to focus on first
(default: the first failing step by number).

---

## Phase 1 — Log Fetch & Triage

### Fetch the job log

```bash
gh api repos/<owner/repo>/actions/jobs/<JOB_ID>/logs
```

### Locate the failure signal for the target step

GHA logs use `##[group]Run <command>` to mark step boundaries and `##[error]` to mark
failures. Search strategy (in order):
1. Find the last `##[error]` line — this is the exit signal
2. Look backwards ~100 lines for the actual error output: stack traces, tool errors,
   compiler output, etc.
3. The preceding `##[group]Run ...` line names the exact command that failed

### Form a best-guess root cause

> **Output format for Phase 1:**
> ```
> 🔍 Best-guess root cause: [concise statement]
> Job: [job name]  Step: [step name]  Command: [command from ##[group] marker]
> Confidence: [high/medium/low]
> Reasoning: [1–2 sentences]
> ```

---

## Phase 2 — Confirm & Diagnose

Ask 2–4 targeted questions to confirm or rule out the root cause. Examples:
- "Did this workflow pass recently, or has it never worked?"
- "Was a dependency version recently bumped?"
- "Is this runner self-hosted or GitHub-hosted?"

**Check user permissions context.** Ask the user directly about their access level —
permissions lookup requires write-scoped API calls that are blocked here. If a fix
requires elevated permissions (secrets, runner config, branch protection), flag it:

```
⚠️ Elevated permissions required: [what needs changing]
Who can help: [team/role, e.g. "repo admins" or specific handles if known]
```

---

## Phase 3 — Fix Recommendation

Suggest fixes once root cause is confirmed:

```
## Root Cause
[Confirmed statement — include job name and step]

## Severity
[Blocking / Non-blocking / Flaky]

## Suggested Fix
[Step-by-step instructions the user can act on given their permissions]

## References
- [Link to relevant compiler/tool docs]
- [Link to relevant GHA runner docs, if applicable]
```

**Research priority:** 1) failing stack trace clues, 2) official docs for the failing
tool, 3) GitHub Actions runner documentation.

---

## Common Failure Patterns (quick reference)

| Pattern | Signal | Likely cause |
|---------|--------|-------------|
| Dependency install fail | `npm ERR!`, `pip install` exit 1 | Version conflict, registry outage, lockfile mismatch |
| Permissions / auth fail | `403`, `Resource not accessible by integration` | Missing secret, token scope, GITHUB_TOKEN permissions |
| Flaky test | Passes locally, fails intermittently in CI | Race condition, environment diff, timing |
| Runner OOM | `The runner has received a shutdown signal` | Job exceeds RAM, large artifact, memory leak |
| Docker build fail | `failed to solve`, `COPY failed` | Missing file, wrong context path, base image pull limit |
| Browser binary missing | `The browser folder exists but the executable is missing` | Puppeteer/Playwright post-install script failed or cache corrupted |

---

## Negative Examples (do NOT trigger this skill for these)

- "How do I write a reusable workflow?" → general authoring question, answer directly
- "Can you fix my YAML indentation?" → formatting help, no diagnosis needed
- "My workflow passed, can you summarize what it did?" → passing run, no failure context
- "How do I set up GitHub Actions for the first time?" → setup guide, not log analysis

---

## Limitations

- **`gh run view --log-failed` is unreliable** on large runs (502s). Always use the
  jobs API + per-job log fetching instead.
- **`gh` not installed or not authenticated:** Cannot fetch live run data — user must
  paste the failed job log (see `references/preflight-recovery.md`).
- **Permissions lookup:** Org role and team membership lookups require write-scoped
  tokens and are blocked. Ask the user directly instead.
- **Truncated logs:** If the key error is cut off, ask the user to download the full
  log from the Actions UI and paste the tail.
- **Private repos:** `gh` must have `repo` scope (read) for the target org. On 404
  or 403, ask the user to confirm `gh auth status`.
