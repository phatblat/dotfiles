---
name: rerun-until-stable
description: Validate a flaky-test fix on GitHub Actions by re-running the same job repeatedly until it passes N consecutive times or fails once. Use when the user asks to "rerun until stable", "validate the flake fix", "loop the X check until it passes N times", or wants confidence that a flaky CI job is actually fixed by their PR.
user-invocable: true
allowed-tools:
  - Bash
  - Monitor
  - Read
---

# /rerun-until-stable — Validate a flaky GHA job

A single green CI run does not validate a flake fix. The standard bar is **5 consecutive passes** on the *specific* job that flakes (Ditto convention; matches PR #22028's evidence requirement). This skill drives that loop on a single PR's job.

Arguments passed: `$ARGUMENTS`

## When to use

- The user has just pushed/opened a PR that targets a flaky test.
- They want to know whether their fix actually fixed it before merging.
- They name the job, or it's obvious from the PR which one is the suspect (only one Swift/iOS check, only one Lint check failing, etc.).

## When NOT to use

- One-shot "wait for CI to go green" → use `gh pr checks --watch` or Bash with `gh run watch`.
- Validating a non-flaky fix (correctness change) → one green run is enough.
- The user wants to monitor across PRs / channels → use a different skill or polling tool.

## Inputs to gather

Before invoking the script, lock down:

1. **PR number** — from the user, or `gh pr view --json number`.
2. **Run ID** — `gh pr checks <PR>` and pick any URL: `runs/<RUN_ID>/job/<JOB_ID>`. The run ID is stable across rerun attempts; only the job ID changes.
3. **Job name pattern** — the substring that uniquely identifies the flaking job in `gh pr checks` output. Examples:
   - `SDK: Swift (ios-simulator)`
   - `Lint Cocoa`
   - `SDK: .NET - iOS`
   Be exact enough that `grep -E` matches one row and not also a parent job (e.g. `SDK: Swift` would match both `SDK: Swift` and `SDK: Swift (ios-simulator)` — pick the most specific).
4. **Target pass count** — see below.
5. **Already-completed passes** — count any green attempt of the same job *on this PR* before kicking off the loop. The original CI run on push counts.

## Picking the target pass count

- **Default: 5.** Matches Ditto's convention for declaring a flake fix done.
- **Floor: 3.** Below this is not statistically meaningful for a flake.
- **Ceiling: 10.** Past this you are burning CI capacity for no incremental signal.
- If the user gives a number, honor it but clamp to `[3, 10]`. If they say "until I'm confident" with no number, use 5.

State the chosen target and the rationale before starting the loop, so the user can override.

## Picking the timeout

Each ios-simulator-class Swift job is ~12–17 min. .NET iOS is ~15–25 min. Lint jobs are ~3–8 min. Don't guess — read it from CI:

```bash
# Get the duration of the most recent completed instance of this job on this PR
DURATION_RAW=$(gh pr checks <PR> 2>/dev/null \
  | grep -E "<JOB_NAME_PATTERN>" \
  | head -1 \
  | awk -F'\t' '{print $3}')
# Convert "12m8s" / "1h2m3s" / "45s" → seconds
SEC=$(printf '%s' "$DURATION_RAW" | awk '
  { s=0; gsub(/h/," h ",$0); gsub(/m/," m ",$0); gsub(/s/," s ",$0);
    n=split($0,a," ");
    for (i=1;i<=n;i+=2) {
      v=a[i]+0; u=a[i+1];
      if (u=="h") s+=v*3600; else if (u=="m") s+=v*60; else if (u=="s") s+=v;
    }
    print s
  }')
```

Compute total wall time:

```
remaining = TARGET - PASSED_SO_FAR
EXPECTED_SECONDS = remaining * SEC * 1.5    # 50% buffer
```

Then choose the Monitor invocation:

- If `EXPECTED_SECONDS <= 3600` (Monitor's max single-task timeout): use `timeout_ms = EXPECTED_SECONDS * 1000`, `persistent: false`.
- If `EXPECTED_SECONDS > 3600` (will happen any time TARGET-PASSED ≥ ~4 for a 17-min job): use `persistent: true` and omit/ignore `timeout_ms`.

Always tell the user the wall-clock estimate before arming.

## The script

```bash
set -u
PR=<PR>
RUN=<RUN_ID>
JOB_NAME_PATTERN='<JOB_NAME_PATTERN>'   # exact substring; use \( \) to escape parens
TARGET=<TARGET>                          # 3..10
PASSED=<INITIAL_PASSED>                  # count of green attempts already on the books
LAST_JOB=""
LAST_STATUS=""
PENDING_RERUN=0   # set after a counted PASS until we observe a new attempt

echo "MONITOR_START pr=$PR target=$TARGET initial_passes=$PASSED job_pattern=\"$JOB_NAME_PATTERN\""

while [ "$PASSED" -lt "$TARGET" ]; do
  LINE=$(gh pr checks "$PR" 2>/dev/null | grep -E "$JOB_NAME_PATTERN" | head -1 || true)
  STATUS=""
  JOB_ID=""
  if [ -n "$LINE" ]; then
    STATUS=$(printf '%s' "$LINE" | awk -F'\t' '{print $2}')
    JOB_URL=$(printf '%s' "$LINE" | awk -F'\t' '{print $4}')
    JOB_ID=$(printf '%s' "$JOB_URL" | grep -oE '/job/[0-9]+' | grep -oE '[0-9]+$' || true)
  fi

  # New attempt detected — reset transition tracking and clear any pending rerun
  # (the rerun we asked for has materialized).
  if [ -n "$JOB_ID" ] && [ "$JOB_ID" != "$LAST_JOB" ]; then
    echo "ATTEMPT_NEW job=$JOB_ID status=$STATUS"
    LAST_JOB="$JOB_ID"
    LAST_STATUS=""
    PENDING_RERUN=0
  fi

  # Pass transition: count, then queue a rerun unless we hit TARGET.
  if [ "$STATUS" = "pass" ] && [ "$LAST_STATUS" != "pass" ]; then
    PASSED=$((PASSED + 1))
    echo "PASS #$PASSED job=$JOB_ID"
    if [ "$PASSED" -lt "$TARGET" ]; then
      PENDING_RERUN=1
    fi
  # First-failure: stop immediately. The user will want to look at the failure
  # before any more capacity gets burned.
  elif { [ "$STATUS" = "fail" ] || [ "$STATUS" = "failure" ]; } && [ "$LAST_STATUS" != "fail" ] && [ "$LAST_STATUS" != "failure" ]; then
    echo "FAIL_DETECTED job=$JOB_ID — STOPPING"
    exit 1
  fi

  # Rerun loop: keep trying until the API call succeeds AND a new attempt
  # appears (the JOB_ID-changed branch above clears PENDING_RERUN). This
  # is the only path that breaks the "stuck on stale pass" race.
  if [ "$PENDING_RERUN" -eq 1 ] && [ -n "$JOB_ID" ]; then
    echo "RERUN triggering job=$JOB_ID"
    if gh run rerun "$RUN" --job "$JOB_ID" >/dev/null 2>&1; then
      echo "RERUN ok"
      sleep 45   # let GH spin up a new attempt before next poll
    else
      echo "RERUN api error — will retry on next poll"
      sleep 30
    fi
    LAST_STATUS="$STATUS"
    continue
  fi

  LAST_STATUS="$STATUS"
  sleep 60
done

echo "DONE passes=$PASSED — flake fix validated"
```

## Invoking it

Use the `Monitor` tool with:

- `description: "PR #<PR> <JOB_NAME> rerun loop"`
- `command:` the script above with placeholders filled in
- `persistent: true` if `EXPECTED_SECONDS > 3600`, else `false` with `timeout_ms`
- The script writes one line per state transition — those become the user-visible notifications. Don't add other output.

## Reporting

- Before arming: state target, current passes, expected wall-clock time, and the job being watched. Let the user override.
- During: don't narrate. The Monitor events speak for themselves.
- On `FAIL_DETECTED`: pull the failed run's logs (`gh run view --job <ID> --log-failed`) and report which test failed and the failure mode. Do not auto-rerun.
- On `DONE passes=N`: confirm the loop hit target, suggest merging.

## Edge cases

- **`gh run rerun` rate-limited or transient API failure**: the script logs `RERUN api error — will retry on next poll` and proceeds; the next poll will see `STATUS != pass` is still true (no new attempt was created) and re-attempt the rerun via the same path on the next pass-transition. Keep an eye on this — repeated `RERUN api error — will retry on next poll` means something is wrong with auth or the run state, not just rate limiting.
- **Run is stale / closed**: if the PR is closed or the run is unavailable, `gh run rerun` errors. Stop the loop and tell the user.
- **Job pattern matches multiple rows**: tighten the pattern. The script uses `head -1` which silently picks one — that's wrong if there's ambiguity.
- **Multiple flaky jobs on the same PR**: run one Monitor per job. Don't try to interleave them in one script.
