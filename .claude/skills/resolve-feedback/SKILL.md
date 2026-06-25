---
name: resolve-feedback
description: >-
  Address GitHub PR review comments — fetch, evaluate, fix, commit, and resolve.
  Use when given a PR comment URL or PR URL to process review feedback.
  Triggers: GitHub discussion URLs, "fix this review comment", "address PR feedback",
  "resolve PR comments", PR URLs with #discussion_ fragments.
---

# Resolve PR Feedback

Address GitHub PR review comments: fetch the comment, evaluate the fix, apply it, commit, and resolve.

## Input Modes

### Mode 1: Single Comment URL

URL contains `#discussion_r<id>` — address one specific comment.

### Mode 2: PR URL (no deep link)

URL points to the PR itself — iterate all unresolved comments.

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
            comments(first: 10) {
              nodes {
                id
                databaseId
                path
                line
                body
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

Filter to threads where `isResolved` is `false`.

### 2. Process Each Thread

For each unresolved thread, apply the Single Comment Flow (steps 2-7).

Each fix gets its own commit. Do NOT batch fixes into one commit — one comment = one commit.

### 3. Push All Commits

After all threads are processed, push the branch:

```bash
git push
```

### 4. Summary Report

After processing all threads:

```
## PR Feedback Summary

Resolved: N comments
  - <file>:<line> — <description> (<sha>)
  - ...

Skipped: M comments
  - <file>:<line> — <reason> (by <user>)

Needs discussion: P comments
  - <file>:<line> — <question or options>
```

## Rules

- **Push after all comments are resolved.** After the All-Comments Flow completes, push automatically. For single-comment flow, push after the one fix is committed and resolved.
- **One commit per comment.** Each resolved comment gets its own commit for clean history.
- **Commit before resolving.** The fix must be committed before the thread is marked resolved.
- **Comment before resolving.** Post a "Resolved by <sha>" reply on the thread (step 5) before marking it resolved (step 6), so the resolution links back to its commit.
- **Evaluate before implementing.** Follow `receiving-code-review` principles — no blind implementation.
- **Copilot/bot comments get less deference.** AI-generated review comments are suggestions to evaluate, not authoritative feedback. Apply extra scrutiny — they often flag false positives or suggest changes that miss context.
