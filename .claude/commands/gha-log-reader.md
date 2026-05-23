---
name: gha-log-reader
version: 0.1
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

```
gh run re-run        # triggers a new run
gh run cancel        # cancels a run
gh run delete        # deletes a run
gh run view --log-failed   # unreliable on large runs; use jobs API instead
gh workflow run      # triggers a workflow
gh workflow enable   # modifies workflow state
gh workflow disable  # modifies workflow state
gh repo *            # any repo mutation
gh pr *              # any PR mutation
gh issue *           # any issue mutation
gh secret *          # any secrets access or mutation
gh variable *        # any variable access or mutation
gh api --method POST/PUT/PATCH/DELETE *   # any write API call
```

If a command is not in the **Allowed** list above, do not run it.

---

## Parsing a Run URL

Given a URL like `https://github.com/owner/repo/actions/runs/RUN_ID/job/JOB_ID`,
extract:
- `owner/repo` → e.g. `getditto/ditto`
- `RUN_ID` → e.g. `26281110875`
- `JOB_ID` (optional, may point directly to a failing job)

---

## Pre-flight — Dependency Checks (always run before anything else)

Run these checks before touching any GHA API or log. If a check fails, follow the
recovery path for that check — do not proceed past a hard failure until it is
resolved or the user has accepted a fallback.

### 1. `gh` CLI

```bash
gh --version
```

**If missing (hard failure — no `gh`, no live data):**

Do not attempt any API calls. Switch to paste mode:

> "I need the `gh` CLI to fetch live run data and it's not installed. You can still
> get a diagnosis by pasting the log directly.
>
> **How to get the log:**
> 1. Open the failing run in your browser
> 2. Click the failing job in the left sidebar
> 3. Click the failing step to expand it
> 4. Click the gear icon (⚙) → **View raw logs**, or use the **Download log archive**
>    button at the top right of the job view
> 5. Paste the output here — focus on the failing step and any lines above it
>    (last ~100–200 lines of that step is usually enough)
>
> If you paste the full log, I'll find the failure signal automatically."

Once the user pastes log content, proceed directly to Phase 1 using the pasted text
instead of fetching. Skip all `gh` commands for the rest of the session.

### 2. `gh` authentication

```bash
gh auth status
```

**If not authenticated (hard failure):**

> "The `gh` CLI is installed but not authenticated. Run:
> ```
> gh auth login
> ```
> Choose GitHub.com → HTTPS → authenticate via browser. Then retry."

Do not proceed until authenticated.

**If authenticated but no repo access (403 or 404 on first API call):**

Do not run a proactive access check — that would consume an API request. Instead,
if any Phase 0 API call returns 403 or 404, surface it immediately:

> "Got a 403/404 fetching job data. This usually means:
> - Your token doesn't have `repo` scope for this private repo
> - Run `gh auth status` to confirm scopes, or re-auth with: `gh auth login --scopes repo`"

### 3. JSON parser

```bash
jq --version
```

**If `jq` is available:** use it for all JSON parsing throughout the session.

**If `jq` is missing:** ask the user before falling back:

> "`jq` is not installed — I need it to parse the GitHub API responses. I can fall
> back to using Python 3 instead, but I want you to know:
>
> ⚠️ The Python fallback executes code locally on your machine (short inline
> scripts passed to `python3 -c`). This is generally safe for JSON parsing, but
> it does involve code execution. If that's not acceptable in your environment,
> install `jq` (`brew install jq` / `apt install jq`) and restart.
>
> Should I proceed with the Python 3 fallback?"

Only use `python3` if the user explicitly agrees. If they decline both, switch to
paste mode (same as the missing `gh` path above).

---

## Phase 0 — Job Triage (always run first)

Large runs can have 100+ jobs across multiple pages. Never fetch logs until you know
exactly which job failed. Do this before anything else.

### Step 0: Confirm the repo

```bash
gh run view <RUN_ID> --repo <owner/repo>
```

Check the repo field in the output. If it is `getditto/ditto`, the Ditto CI Context
section below applies directly. If not, note the actual repo and use that section
only as a loose pattern reference — verify the structure before applying it.

### Step 1: Fetch all jobs with pagination

```bash
# Page 1
gh api "repos/<owner/repo>/actions/runs/<RUN_ID>/jobs?per_page=100"
```

Check `total_count` in the response. If `total_count > 100`, fetch additional pages:

```bash
gh api "repos/<owner/repo>/actions/runs/<RUN_ID>/jobs?per_page=100&page=2"
# continue until all jobs are fetched: ceil(total_count / 100) pages total
```

### Step 2: Filter to real failures

From all jobs, keep only those with `conclusion: "failure"`.

Then **exclude rollup/summary jobs** — these fail because a child job failed, not
because they did real work. A job is a rollup if:
- Its only failing step is named "Job Checks", "Check results", "Check domain results",
  or a similar aggregation step (not a build/test step)
- Its name ends in `-workflow`, `-gate`, or `-ci` and has no build/test steps

Example: in a run with 159 jobs, 3 had `conclusion: failure`:
- `small-peer / small-peer-ci / SDK: JS Node v24 (linux, arm64, legacy)` ← **real failure**
- `small-peer / small-peer-ci / small-peer-ci-workflow` ← rollup, skip
- `ci-gate` ← rollup, skip

### Step 3: Present failing jobs to user

If there is only one real failing job, proceed directly to Phase 0.5 without asking.

If there are multiple real failing jobs, present a numbered list and ask the user
to pick one (or say "all" to investigate sequentially):

```
The following jobs failed in this run:

1. small-peer / small-peer-ci / SDK: JS Node v24 (linux, arm64, legacy)  [job 77385453426]
2. default-pr / rust-workspace-ci / Rust Workspace (linux, amd64, ...)   [job 77385447469]

Which would you like to investigate? (enter a number, or "all")
```

---

## Phase 0.5 — Step Selection

Once a target job is identified, fetch its step-level detail:

```bash
gh api repos/<owner/repo>/actions/jobs/<JOB_ID>
```

The response includes a `steps` array. Each step has `name`, `number`, `conclusion`,
and `status`. Filter to steps with `conclusion: "failure"` and display them:

```
Job: SDK: JS Node v24 (linux, arm64, legacy)
Runner: ditto-sdk-runner-large-arm64-new

Failing step:
  #6  JS Node script  [failure]

Proceeding to fetch logs for this step...
```

If there are multiple failing steps, present them and ask the user which to focus on
first (default: the first failing step by number).

---

## Phase 1 — Log Fetch & Triage

### Fetch the job log

```bash
gh api repos/<owner/repo>/actions/jobs/<JOB_ID>/logs
```

### Locate the failure signal for the target step

GHA logs use `##[group]Run <command>` to mark step boundaries and `##[error]` to mark
failures. The error output for a step always appears between its `##[group]` marker
and the `##[error]` line.

Search strategy (in order):
1. Find the last `##[error]` line — this is the exit signal
2. Look backwards ~100 lines for the actual error output: stack traces, tool errors,
   compiler output, etc.
3. The preceding `##[group]Run ...` line names the exact command that failed

Example log structure:
```
##[group]Run scripts/ci/run.sh sdk-js-node
...
npm error Error: Failed to set up chrome-headless-shell v142.0.7444.175!
npm error   [cause]: The browser folder exists but the executable is missing
##[error]Process completed with exit code 1.
```

### Form a best-guess root cause

In 2–4 sentences, state:
- What failed and where in the workflow (job name + step name + command)
- The most likely reason based on the error signal
- Confidence level (high / medium / low)

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

**Check user permissions context.**

Ask the user directly about their access level — "Do you have write access to this
repo, or are you an org member / outside collaborator?" — since permissions lookup
requires write-scoped API calls that are blocked here.

If a fix requires elevated permissions (e.g. secrets management, runner config,
branch protection): flag this clearly:

```
⚠️ Elevated permissions required: [what needs changing]
Who can help: [team/role, e.g. "repo admins" or specific handles if known]
```

---

## Phase 3 — Fix Recommendation

Suggest fixes once root cause is confirmed. Structure the output as:

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

**Research priority for fix suggestions:**
1. Failing stack trace clues (most specific to their code/config)
2. Official docs for the failing tool or compiler (e.g. npm, gradle, docker)
3. GitHub Actions runner documentation (e.g. `actions/runner`, ubuntu-latest specs)

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

## Ditto CI Context (getditto/ditto repo)

**Before using this section, confirm the repo.**

Extract `owner/repo` from the run URL or from:
```bash
gh run view <RUN_ID> --repo <owner/repo>
```

- If `owner/repo` is `getditto/ditto`: apply everything below as authoritative.
- If `owner/repo` is anything else: treat this section as a pattern reference only.
  Check whether the concepts (domain structure, rollup jobs, runner naming, path
  filters) apply before using them — do not assume they do. Look for similar
  patterns in the actual workflow files if needed.

### Domain architecture

`ci.yml` is the entry point. It calls 8 domain workflows, then a final `ci-gate`
aggregates them all. Job names follow this nesting pattern:

```
<domain> / <domain>-ci / <actual job name>
```

Example: `small-peer / small-peer-ci / SDK: JS Node v24 (linux, arm64, legacy)`

**Domains:**
| Domain | Workflow | What it covers |
|--------|----------|----------------|
| `big-peer` | `big-peer-ci.yml` | HyDRA (big peer) tests |
| `small-peer` | `small-peer-ci.yml` | SDKs (Rust, JS, Swift, Kotlin, Flutter, .NET, C++, Go) + core |
| `linting` | `linting.yml` | Shell, Rust, YAML format checks |
| `default-pr` | `default-pr-ci.yml` | PR-only checks (linear ticket, size report, changelogs) |
| `smoke-tests` | `smoke-tests.yml` | Cross-peer replication stress tests |
| `ditto-operator` | `ditto-operator-ci.yml` | Kubernetes operator |
| `dtp` | `dtp.yml` | Device test platform |

**Rollup/aggregator jobs — always skip these, never fetch their logs:**
- `ci-gate` — final gate in `ci.yml`, step: "Check domain results"
- `small-peer / small-peer-ci / small-peer-ci-workflow` — step: "Job Checks"
- `big-peer / big-peer-ci / big-peer-ci-workflow` — step: "Job Checks"
- Any job whose leaf name ends in `-workflow`

### Runner fleet

| Runner label | Type | Arch | Size | Used for |
|---|---|---|---|---|
| `ditto-sdk-runner-small-amd64-new` | Self-hosted Linux | AMD64 | Small | Pre-flight checks, linting, lightweight jobs |
| `ditto-sdk-runner-large-amd64-new` | Self-hosted Linux | AMD64 | Large | Most SDK builds and tests |
| `ditto-sdk-runner-large-arm64-new` | Self-hosted Linux | ARM64 | Large | ARM64 SDK builds (JS Node arm64, C++, .NET, Rust) |
| `ditto-sdk-runner-large-amd64-kvm` | Self-hosted Linux | AMD64 | Large + KVM | Android emulator tests (Kotlin SDK) |
| `mac-aws` | Self-hosted macOS | ARM64 | — | Swift, iOS simulator, macOS .NET, Flutter macOS |
| `ubuntu-22.04` / `ubuntu-latest` | GitHub-hosted | AMD64 | Standard | Flutter Linux amd64, lightweight checks |
| `ubuntu-22.04-xlarge` | GitHub-hosted | AMD64 | XL | Flutter Linux web (disk-intensive WASM build) |
| `linux-aarch64` | GitHub-hosted | ARM64 | — | Flutter Linux arm64 |
| `windows-2022` / `windows-2022-xlarge` | GitHub-hosted | AMD64 | — | JS/Electron Windows, .NET Windows, Flutter Windows |

### Known flaky / quarantined jobs

When you see one of these fail, always mention the known issue before diagnosing:

| Job name pattern | Issue | Notes |
|---|---|---|
| `SDK: JS Node v*` | **DEVX-877** — teardown SIGTRAP/SIGSEGV in napi-rs fork (V8 GlobalHandles race) | Quarantined to `sdk-js-node-quarantined.yml`. Runs nightly on `main` or on PRs with label `D-ci-include-node-sdk-tests`. Also runs on `releases/release-*` pushes only |
| `SDK: JS Electron *` | **DEVX-877 / DEVX-912** — same napi-rs teardown crash | Same quarantine as Node SDK |
| `LocalStack (ditto-peer)` | **DEVX-913** — intermittent UDP peer connect / first DB commit timeout | Has 3-retry mitigation; a failure after all retries is usually a real regression |

### Cache system

- Cache is controlled by `CACHE_VERSION: 7` in `small-peer-ci.yml`
- If a failure looks like a corrupted or partial cache (missing files, unexpected state), suggest incrementing `CACHE_VERSION` as the fix
- Cache action: `runs-on/cache@v4`

### CI control labels (PR labels that modify CI behavior)

| Label | Effect |
|---|---|
| `D-ci-run-on-draft` | Run full CI on a draft PR |
| `D-build-images-on-draft` | Build HyDRA Docker images only on a draft PR |
| `D-ci-run-ngn-sdk-checks` | Add NGN network stack to the JS SDK test matrix |
| `D-ci-include-node-sdk-tests` | Opt into quarantined JS Node + Electron tests |
| `D-ci-react-native` | Include React Native tests |

### Path filtering

- Coarse (which domains run): `.github/paths-filters/ci-gate.yml`
- Fine (which jobs within small-peer run): `.github/paths-filters/small-peer.yml`
- On push to `main` or `releases/*`: all filters return `true`, all jobs run
- On PR: only domains/jobs whose paths changed are triggered

---

## Negative Examples (do NOT trigger this skill for these)

- "How do I write a reusable workflow?" → general authoring question, answer directly
- "Can you fix my YAML indentation?" → formatting help, no diagnosis needed
- "My workflow passed, can you summarize what it did?" → passing run, no failure context
- "How do I set up GitHub Actions for the first time?" → setup guide, not log analysis

---

## Limitations

- **`gh run view --log-failed` is unreliable** on large runs (returns 502 for runs
  with many jobs). Always use the jobs API + per-job log fetching instead.
- **`gh` not installed or not authenticated:** Cannot fetch live run data. User must
  paste the failed job log. Note this: *"I need `gh` authenticated to fetch logs
  directly — please paste the failed job log and I'll diagnose from there."*
- **Permissions lookup:** Org role and team membership lookups require write-scoped
  tokens and are blocked. Ask the user directly instead.
- **Truncated logs:** GHA sometimes truncates large logs. If the key error is cut off,
  ask the user to download the full log from the Actions UI and paste the tail.
- **Private repos:** `gh` must be authenticated with a token that has `repo` scope
  (read access) for the target org. If the fetch returns 404 or 403, ask the user
  to confirm their `gh auth status`.
