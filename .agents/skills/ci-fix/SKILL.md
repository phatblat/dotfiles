---
name: ci-fix
version: 0.1
description: >
  Investigate and fix failing CI. Takes a PR reference, one or more CI run/job
  URLs, or freeform text describing where the failures are, then enumerates
  failing workflows/jobs/steps, determines the root cause (often one shared
  cause behind several red checks), proposes a fix plan, applies code changes,
  commits, pushes, watches the new runs, and repeats until checks pass. Use
  when the user says "fix CI", "CI is red", "checks are failing", "the build is
  broken on my PR", "fix the failing jobs", or pastes a failing CI run URL. Do
  NOT use for authoring new workflows, or for read-only diagnosis with no fix
  intent — use gha-log-reader for that.
compatibility:
  gh_cli: required
---

# CI Fix

Drive failing CI to green: resolve the target, enumerate failures, extract
evidence, cluster into root causes, fix the narrowest way possible, push, and
watch — repeating until checks pass or a stop condition trips.

## 1. Resolve the target

Priority order:

1. **GHA run/job URL** — `https://github.com/{owner}/{repo}/actions/runs/{run_id}`
   optionally `/job/{job_id}`; parse `owner`, `repo`, `run_id`, `job_id`.
2. **PR reference** — `#N`, `N`, `owner/repo#N`, or PR URL:
   ```bash
   gh pr view <ref> --json number,headRefName,headRefOid,baseRefName,url,isCrossRepository
   ```
3. **Branch name** — `gh run list --branch <branch> --limit 20`.
4. **Nothing / prose only** — default to the current branch's PR (`gh pr view --json ...`
   with no ref); if no PR, fall back to `gh run list --branch "$(git branch --show-current)"`.
5. **Freeform text** — never discard. Treat as a scope hint narrowing which
   failures to attack (e.g. "the lint and agent-harness checks are failing")
   and echo it back as the user's stated scope.

Ambiguity rule: if the input resolves to more than one plausible PR or repo,
stop and ask once, listing candidates. Never guess a repo.

Non-GitHub URL (GitLab, Buildkite, CircleCI, Jenkins, Azure): fetch the URL,
read the visible log text, and continue with the same clustering logic. State
plainly that reproduction and watch automation are GHA-only; non-GHA targets
get analysis + a fix, with re-run verification left to the user.

## 2. Enumerate failures

- Get the whole picture in one pass, not per-job round trips:
  ```bash
  gh pr checks <ref> --json name,state,bucket,link,workflow,description
  gh run list --branch <branch> --limit 20 \
    --json databaseId,name,conclusion,status,event,headSha,workflowName,createdAt
  ```
  Field names for `gh pr checks --json` vary by `gh` version; if it errors,
  run `gh pr checks --json 2>&1` — it prints the valid field list — and use
  that.
- Keep only `failure`, `cancelled`, `timed_out`, `action_required`,
  `startup_failure`. `cancelled` is usually collateral from a fail-fast
  sibling and must not be counted as its own root cause.
- **Discard runs not against the current head SHA**, with a one-line note.
  Chasing an already-fixed failure from a superseded push is the most common
  wasted loop.
- Drill to failing jobs and steps:
  ```bash
  gh run view <run_id> --json jobs \
    --jq '.jobs[] | select(.conclusion=="failure") | {name, databaseId, steps: [.steps[] | select(.conclusion=="failure") | {name, number}]}'
  ```
- Emit a **failure inventory table** (workflow → job → step → one-line
  symptom) before any analysis. This table is the loop's unit of progress and
  is re-emitted each iteration.

## 3. Extract evidence

- Invoke the **`gha-log-reader`** skill per failing job by name; do not dump
  raw logs into context.
- Fallback when unavailable: `gh run view <run_id> --log-failed --job <job_id>`,
  capped at the first error line plus the last ~100 lines of the failing
  step. (Do not use `gh job view` — it is not a stable `gh` command.)
- Extract per failure: failing command, exit code, primary error line(s),
  `file:line` when present.
- Read the workflow definition — this is what makes local reproduction
  possible:
  ```bash
  gh run view <run_id> --json workflowName,path
  ```
  then read `.github/workflows/<file>` locally at the head SHA, noting
  `working-directory`, `env`, and matrix values for the failing leg.

## 4. Cluster into root causes

Group by cause, not by job. Signals that two failures share one cause:
identical error text, same failing file, same tool/step name across matrix
legs, or a common upstream artifact/job.

Classify each cluster into exactly one:

- **Code defect** — the change under test is wrong. Fix the code.
- **Generated-artifact drift** — a generator's output is stale relative to
  its source. **High prior in this repo**: `~/scripts/agent-harnesses.py`
  generates `~/.agents/harness/**` and the native adapter trees, and
  `just harness-check` fails on stale artifacts. Fix by re-running the
  generator (`just harness-generate`), never by hand-editing generated
  output.
- **Config/workflow defect** — workflow YAML, action version, or CI config
  is wrong.
- **Environment/infra** — runner outage, network, registry, rate limit,
  missing secret. Not fixable by a code change.
- **Flake** — non-deterministic; test by re-running the same SHA with no
  code change.
- **Pre-existing on base** — reproduces on the base branch, so not caused by
  this PR. Verify rather than assert:
  ```bash
  gh run list --branch <baseRefName> --limit 5 --json conclusion,workflowName,headSha
  ```

**Attempt local reproduction before editing.** Derive the local command from
the failing workflow step (honoring `working-directory` and required env),
run it, and confirm it fails the same way. A locally validated fix saves a
full CI round trip. If the step cannot run locally (needs secrets, a specific
runner, service containers), say so and proceed to a reasoned fix.

## 5. Fix

- Present a cause → fix table before editing.
- Apply the **narrowest** change per root cause.
- **Hard rule:** never disable or skip tests, loosen lint rules, add
  `continue-on-error`, weaken assertions, or edit fixtures/expected values to
  make a check pass. Suppressing a check is not fixing CI. If the only
  viable fix is suppression, stop and ask.
- Environment/infra clusters get **no code change**. Flake clusters get a
  re-run instead: `gh run rerun <run_id> --failed`.
- Commit via the **`git-commit`** skill — one commit per root cause, so a
  revert stays surgical.
- Push via the **`git-push`** skill.
- Refuse to push when the PR head is a fork (`isCrossRepository: true`)
  without write access, or when the working tree carries unrelated staged
  changes — report instead.

## 6. Watch and iterate

- Wait for runs against the **new** head SHA; a run takes a few seconds to be
  created after a push, so poll for its existence before watching:
  ```bash
  gh pr checks <ref> --watch --fail-fast=false
  ```
  or `gh run watch <run_id> --exit-status` for a single run.
- On completion, return to step 2 ("Enumerate failures") with the new head
  SHA.
- **Stop conditions**, all mandatory:
  - all required checks pass → report success with run URL;
  - iteration cap reached (default **5**);
  - the *same* root cause survives **2** consecutive fix attempts → stop;
    repeating a failing strategy signals a wrong diagnosis, so report
    evidence and ask for direction;
  - a fix would require suppressing a check → stop and ask;
  - only environment/infra clusters remain → stop and report.
- Every termination, success or not, ends with: what was fixed, what
  remains, per-cluster evidence, commits pushed.
