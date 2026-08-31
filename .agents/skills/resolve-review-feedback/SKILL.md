---
name: resolve-review-feedback
description: >-
  Address GitHub PR review feedback at line, file, and PR level — fetch, evaluate,
  fix, commit, and resolve. Use when given a PR URL, a review-comment URL, or a
  PR-level comment URL. Triggers: GitHub discussion URLs, "fix this review comment",
  "address PR feedback", "resolve PR comments", PR URLs with #discussion_,
  #issuecomment-, or #pullrequestreview- fragments.
---

# Resolve PR Feedback

Address GitHub PR review comments: fetch the comment, evaluate the fix, apply it, commit, and resolve.

## Input Modes

### Mode 1: Single Comment URL

URL contains `#discussion_r<id>` — address one specific comment.

### Mode 2: PR URL (no deep link)

URL points to the PR itself — iterate every unresolved line-level thread, file-level thread, and PR-level comment.

### Mode 3: PR-level comment or review URL

URL contains `#issuecomment-<id>` (a PR-level comment) or `#pullrequestreview-<id>`
(a review body) — address one PR-level finding via the PR-Level Flow below.

## Single Comment Flow

### 1. Fetch the Comment

Extract owner, repo, PR number, and comment ID from the URL.

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id} --jq '{
  id: .id,
  path: .path,
  line: .line,
  side: .side,
  body: .body,
  diff_hunk: .diff_hunk,
  subject_type: .subject_type,
  user: .user.login
}'
```

If the comment includes a suggested code change (GitHub suggestion block in the body), extract the suggested code.

### 2. Evaluate the Change

Apply the `receiving-code-review` skill principles:

- **Clear and correct**: The fix is obvious, unambiguous, and technically sound. Apply immediately.
- **Ambiguous or multiple approaches**: Present the options to the user with `AskUserQuestion` before changing code.
- **Disagree**: Push back with technical reasoning. Do not implement.
- **Can't verify**: State what's unclear and ask for direction.

### 3. Apply the Fix

Read the file at `path`, make the change with `Edit`.

### 4. Commit Immediately

Stage only the changed file(s) and commit using `/git:commit` conventions:

```
fix: <concise description of what the review comment asked for>
```

### 5. Post the Resolution Comment

Before resolving the thread, reply to it referencing the commit that addressed it. Use the short SHA from step 4's commit:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
  -f body="Resolved by <sha>"
```

`<sha>` is the commit SHA from step 4 (`git rev-parse --short HEAD` after committing). This leaves an audit trail in the thread linking the resolution to its fix before the thread is collapsed.

### 6. Resolve the Comment

Mark the review thread as resolved:

```bash
gh api graphql -f query='
  mutation {
    resolveReviewThread(input: {threadId: "<thread_node_id>"}) {
      thread { isResolved }
    }
  }
'
```

To get the thread node ID from a comment:

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id} --jq '.node_id'
```

Then find the thread it belongs to:

```bash
gh api graphql -f query='
  query {
    node(id: "<comment_node_id>") {
      ... on PullRequestReviewComment {
        pullRequestReviewThread { id isResolved }
      }
    }
  }
'
```

### 7. Report

```
Fixed: <file>:<line> — <what changed>
Committed: <short sha> <commit message>
Resolved: comment by <user>
```

## All-Comments Flow (PR URL)

### 1. Fetch All Unresolved Comments

```bash
gh api graphql -f query='
  query {
    repository(owner: "{owner}", name: "{repo}") {
      pullRequest(number: {pr}) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            subjectType
            path
            line
            comments(first: 10) {
              nodes {
                id
                databaseId
                path
                line
                body
                diffHunk
                author { login }
                createdAt
              }
            }
          }
        }
      }
    }
  }
'
```

Filter to threads where `isResolved` is `false`. Both `subjectType` values are in
scope and handled identically — a `FILE` thread is feedback on the file as a whole
(review comments made outside any diff line) and it resolves through
`resolveReviewThread` exactly like a `LINE` thread.

`line: null` does **not** mean file-level. It means the thread is outdated
(`isOutdated: true`) because the diff moved under it; `subjectType` is still `LINE`.
For those, locate the code by the `path` plus the quoted `diff_hunk` from the
comment body rather than by line number.

### 2. Process Each Thread

For each unresolved thread, apply the Single Comment Flow (steps 2-7).

Each fix gets its own commit. Do NOT batch fixes into one commit — one comment = one commit.

### 3. Process PR-Level Findings

After processing all line/file threads, process PR-level comments and reviews via the
PR-Level Flow below.

### 4. Push All Commits

After all threads and PR-level findings are processed, push the branch:

```bash
git push
```

### 5. Summary Report

After processing all threads and PR-level findings:

```text
## PR Feedback Summary

Line/file threads — resolved: N
  - <path>:<line> [LINE|FILE] — <description> (<sha>)

PR-level comments — resolved: N
  - <path>:<line> — <description> (<sha>) [minimized|replied, not minimized]

Skipped: M
  - <locator> — <reason> (by <user>)

Already handled: K
  - <locator> — <minimize marker | resolution claim in <url>, verified>

Needs discussion: P
  - <locator> — <question or options>
```

## PR-Level Flow

PR-level feedback lives on two surfaces, neither threaded, so `resolveReviewThread`
does not apply to either.

Fetch both in one call:

```bash
gh api graphql -f query='
  query {
    repository(owner: "{owner}", name: "{repo}") {
      pullRequest(number: {pr}) {
        comments(first: 100) {
          nodes {
            id
            databaseId
            body
            createdAt
            isMinimized
            minimizedReason
            viewerCanMinimize
            author { login }
            url
          }
        }
        reviews(first: 100) {
          nodes {
            id
            body
            state
            createdAt
            isMinimized
            minimizedReason
            viewerCanMinimize
            author { login }
            url
          }
        }
      }
    }
  }
'
```

Every `comments` node is a candidate finding. A `reviews` node is a candidate only
when `body` is non-empty — a review with an empty body is just the envelope around
inline comments already covered by the thread flow.

Single-target fetches for Mode 3:

```bash
gh api repos/{owner}/{repo}/issues/comments/{comment_id}   # #issuecomment-<id>,  node_id starts IC_
gh api repos/{owner}/{repo}/pulls/{pr}/reviews/{review_id} # #pullrequestreview-<id>, node_id starts PRR_
```

Document the resolution-detection ladder, in order, stopping at the first hit:

1. **Minimize marker.** `isMinimized: true` means already handled — this skill sets
   it in step 4 below. Skip the finding and carry `minimizedReason` into the report.
2. **Later-comment scan.** PR-level findings carry no thread state, so scan every
   comment and non-empty review body with `createdAt` strictly greater than the
   finding's for a claim that resolves or defers it. A body counts as a claim when it
   references the finding **and** carries a resolution or deferral signal:
   - references the finding: the file path from the finding's locator footer (basename
     match is enough), the finding's own comment URL or `#issuecomment-<id>` anchor, or
     a distinctive symbol name quoted in the finding.
   - resolution signal: a 7–40 character hex SHA or a `#<number>` reference together
     with any of `resolved`, `fixed`, `addressed`, `landed`, `implemented`.
   - deferral signal: any of `deferred`, `won't fix`, `wontfix`, `out of scope`,
     `tracked in`, `follow-up`.
3. **Verify or accept the claim.** A resolution claim is a hint, not proof — confirm the
   described change is actually present in the working tree before skipping the finding.
   If absent, treat the finding as unresolved and note the stale claim. A deferral claim
   by definition has no tree change — accept it (optionally checking a referenced
   `#<number>` tracker exists) and report it under Skipped instead of reprocessing.
4. **Otherwise** the finding is unresolved — process it through the Single Comment
   Flow steps 2–4 (evaluate, fix, commit), then mark it handled as below.

Locator footer: review tooling that reposts an out-of-diff finding at PR level
appends a footer naming the original location, in either of these forms (verified on
real comments):

```text
_Originally at: https://github.com/<owner>/<repo>/blob/<sha>/<path>#L82-L88_
_Reviewed against https://github.com/<owner>/<repo>/blob/<sha>/<path>#L214-L215_
```

Parse `<path>` (everything after `blob/<sha>/`) and the `#L<start>[-L<end>]` range to
locate the code. Absent a footer, locate from the body text.

Marking a PR-level finding handled — two calls, in this order, replacing thread
reply + `resolveReviewThread`:

```bash
# 1. Reply. There is no thread, so the comment must identify which finding it answers.
gh api repos/{owner}/{repo}/issues/{pr}/comments \
  -f body="Resolved by <sha> — <path>:<line> <one-line finding summary>"

# 2. Mark it resolved. subjectId is the GraphQL node id (IC_… or PRR_…), not the databaseId.
gh api graphql -f query='
  mutation {
    minimizeComment(input: {subjectId: "<node_id>", classifier: RESOLVED}) {
      minimizedComment { isMinimized minimizedReason }
    }
  }
'
```

Both `IssueComment` and `PullRequestReview` support `minimizeComment`. If
`viewerCanMinimize` is `false`, post the reply, skip the mutation, and record the
finding as "replied, not minimized" in the report — never fail the run over it.

## Rules

- **Push after all comments are resolved.** After the All-Comments Flow completes, push automatically. For single-comment flow, push after the one fix is committed and resolved.
- **One commit per comment.** Each resolved comment gets its own commit for clean history.
- **Commit before resolving.** The fix must be committed before the thread is marked resolved.
- **Comment before resolving.** Post a "Resolved by <sha>" reply on the thread (step 5) before marking it resolved (step 6), so the resolution links back to its commit.
- **Evaluate before implementing.** Follow `receiving-code-review` principles — no blind implementation.
- **Copilot/bot comments get less deference.** AI-generated review comments are suggestions to evaluate, not authoritative feedback. Apply extra scrutiny — they often flag false positives or suggest changes that miss context.
- **All three surfaces, every run.** A PR URL means line-level threads, file-level
  threads, and PR-level comments. Feedback on code outside the diff usually lands on
  the latter two, so a run that only walks `reviewThreads` line comments silently
  misses it.
- **PR-level resolution is reply-then-minimize.** `resolveReviewThread` does not
  apply. Post an identifying `Resolved by <sha>` comment, then
  `minimizeComment(classifier: RESOLVED)` so a later run detects it without
  re-scanning prose.
- **Never trust a resolution claim.** A later comment saying a finding was fixed is a
  hint. Verify the change is in the tree before skipping; report stale claims.
