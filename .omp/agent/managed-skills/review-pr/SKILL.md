---
name: review-pr
description: Structured, risk-aware code review of a GitHub pull request using the gh CLI, with diff triage, unresolved-thread suppression, and severity-grouped findings ending in an approve/request-changes verdict.
---

# Review a Pull Request

Perform a structured, risk-aware code review of a GitHub pull request. Works in any coding-agent harness with the `gh` CLI authenticated.

## Inputs

- A PR reference: URL, `owner/repo#123`, or bare `#123`. Normalize before use with `gh`: URL → as-is; `owner/repo#N` → `gh -R owner/repo pr diff N`; bare `#N` → `gh pr diff N` (targets the repo whose remote the cwd's `origin` points at — if the cwd is not a git repo with a GitHub `origin`, error out rather than guessing). Only the bare `#N` form depends on the cwd; everything after normalization targets GitHub explicitly via `-R`.
- Optional: extra review instructions from the user (e.g. "focus on security").

## Review Thread Suppression

The skill fetches unresolved review threads itself — no caller needs to supply them.

1. **Fetch threads.** After fetching the diff, list unresolved review threads via GraphQL (handles >100 threads via pagination):

```sh
gh api graphql -f query='
query($owner: String!, $name: String!, $number: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes { isResolved path line originalLine startLine originalStartLine }
      }
    }
  }
}' -F owner=<owner> -F name=<repo> -F number=<number>
```

(pass `-F after=<cursor>` for subsequent pages). Keep only unresolved threads (`isResolved: false`) that have a line number; collect all of `line`, `originalLine`, `startLine`, `originalStartLine` per thread.

2. **Apply suppression window.** Default ±5 lines. GitHub thread `line`/`startLine` are positions on the PR head; `originalLine`/`originalStartLine` are on the base. Match the finding's **new-side line** against the thread's current line (`line`/`startLine`); use `originalLine`/`originalStartLine` only when the current line is null (outdated thread). Skip any finding whose file matches a thread's `path` (also match the diff's old path if the file was renamed) AND whose line falls within ±5 lines (inclusive) of any thread line. Those locations are already under discussion — re-reporting them is noise.

3. **Fallback.** If the GraphQL call fails (missing `pullRequest:read` scope, token can't see the repo), run without suppression and note that in the report.

4. **Report.** After the findings, add one line: `Suppressed N findings overlapping existing unresolved threads` — flag if any suppressed finding was High severity, and let that weigh on the verdict rather than silently approving.

If the caller explicitly supplies a thread list (JSON array of `{"path", "lines"}`) or a different window, prefer the caller's values over the built-in fetch.

If a caller passes additional directives, honor them:

- **Base ref**: "Review <url> against origin/<base>" — diff against that specific base ref, not the PR's actual base. `gh pr diff` cannot override the base, so freeze via git instead:
  ```sh
  git fetch origin +pull/<number>/head:refs/remotes/origin/pr/<number> <base>:refs/remotes/origin/<base>
  git diff refs/remotes/origin/<base>...refs/remotes/origin/pr/<number> > "$diff_dir/pr-review.diff"
  ```
  Requires a local clone; if none is available, clone first or fall back to `gh pr diff` and note the base override was not applied.
- **Review-only mode**: "review-only: do not edit files, commit, push, or post GitHub comments" — strictly read-only: no file edits, no commits, no pushes, no `gh pr comment`/review submissions. Report findings in-conversation only.
- **Interactivity**: "Present the report, then remain interactive for follow-up" — deliver the report, then stay in the session answering follow-up questions without re-running the review.

Caller directives take precedence over defaults in this skill (e.g. review-only overrides any temptation to fix things).

## Workflow

1. **Freeze the diff.** Fetch the patch once into a per-run temp dir and work from that snapshot:

```sh
diff_dir="$(mktemp -d)"
gh -R <owner>/<repo> pr diff <number> > "$diff_dir/pr-review.diff"
```

Also fetch metadata: `gh -R <owner>/<repo> pr view <number> --json title,body,baseRefName,headRefName,additions,deletions,changedFiles`. Read the PR description for intent; review the change against that intent. Keep `$diff_dir` for the whole session; clean it up only when the session ends — follow-up questions may still need the frozen snapshot.

1b. **Fetch unresolved threads.** Per "Review Thread Suppression" above — fetch the PR's unresolved review threads now so suppression is ready before analysis begins.

2. **Triage the file list.** Parse the diff per file. EXCLUDE from review (note them, don't review): lockfiles (`*.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Cargo.lock`, etc.), minified (`.min.js/css`), generated (`.generated.`, `.map`, `.snap`), build output (`dist/`, `build/`, `out/`), vendor (`node_modules/`, `vendor/`), and binaries (images, fonts, archives). If nothing reviewable remains, report that.

3. **Scale the review.**
   - Under ~100 changed lines or ≤2 files → single-pass review.
   - Larger diffs → fan out reviewer subagents in parallel (if your harness supports subagents), grouping by locality: same directory/module together, tests with their implementation files. Suggested agent count: <500 lines → 2, <2000 → 4, <5000 → 8, beyond → up to 16.
   - With many subagents, don't paste the whole diff into each prompt; assign file lists and have each agent slice the frozen patch from `$diff_dir/pr-review.diff` for its own files. Never re-derive the diff via local `git diff` — the frozen patch is the source of truth.

4. **Review each file for:**
   - Correctness: logic errors, edge cases, broken invariants, error handling.
   - Security: injection, unsafe deserialization, secrets, authz gaps.
   - API/contract changes: breaking changes, stale callers, missing updates to consumers and tests.
   - Maintainability: dead code, needless complexity — but defer style nitpicks unless the repo enforces them.

   Across all four dimensions: read surrounding file context when a hunk alone is ambiguous — the diff is the delta, not the truth.

5. **Report findings** grouped by severity:
   - **High** — bugs, security issues, breaking changes (blockers).
   - **Medium** — likely bugs, missing test coverage for changed behavior.
   - **Low** — maintainability, minor issues.

   Each finding (all severities): file, line (old/new), what's wrong, why it matters, and a concrete suggested fix. End with an overall verdict: **approve / approve-with-comments / request-changes**, one sentence of justification.

## Rules

- Review ONLY the PR's changes — never flag pre-existing issues in unchanged lines as blockers; note them separately as observations.
- Never re-fetch or re-diff mid-review; work from the frozen snapshot unless a file needs more context. If `$diff_dir` was cleaned up and a follow-up query needs diff content, a single re-fetch for that query is acceptable.
- Verify claims against the actual diff; cite file+line for every finding.
- No cheerleading; if it's clean, say so briefly.
