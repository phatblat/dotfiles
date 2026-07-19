---
name: pr-post-findings
description: Post findings from the most recent review output as inline GitHub PR comments and record them in today's daily note. Use when invoked as `$pr-post-findings` or when the user asks to post review findings to the current PR.
---

# pr-post-findings

Post findings from the most recent review or code-review output in the conversation as inline comments on the current PR, then append the posted comments to today's daily note.

## Workflow

1. Parse findings from the recent conversation. Expected shape:

   ```text
   N. <description>
   https://github.com/<owner>/<repo>/blob/<full-sha>/<path>#L<start>-L<end>
   ```

   If no findings are available, stop and ask the user to run a review first.

2. If the user provided arguments such as `1,2,4`, keep only those finding numbers. Warn for requested numbers that do not exist.

3. Get PR context:

   ```bash
   gh pr view --json number,headRefOid,url --jq '"\(.number)|\(.headRefOid)|\(.url)"'
   ```

   If no open PR exists, stop and tell the user to run `$pr-create` first.

4. For each finding, extract path and use the last linked line as the comment anchor. Post an inline review comment:

   ```bash
   gh api repos/{owner}/{repo}/pulls/<pr_number>/comments \
     --method POST \
     --input -
   ```

   JSON body:

   ```json
   {
     "body": "<description>",
     "commit_id": "<headRefOid>",
     "path": "<path>",
     "line": <line>,
     "side": "RIGHT"
   }
   ```

   Capture the created comment URL:

   ```bash
   comment_url=$(printf '%s' "$resp" | jq -r '.html_url')
   ```

   Record `{number, description, path, line, comment_url, kind}` for every posted finding. Use `kind=inline` for successful inline comments.

5. If inline posting fails because the line is not in the diff, fall back to:

   ```bash
   gh pr comment <pr_number> --body "<description>\n\n_Originally at: <url>_"
   ```

   Capture the fallback comment URL when possible. If `gh pr comment` prints only a success line, query recent PR comments or use the PR URL as a last-resort link. Record `kind=general`.

6. Record in today's daily note.

   Append this review to the `# Reviews` section of today's daily note (seeded by `$work-start`) so the worklog captures which PRs you reviewed and every comment you left.

   Resolve the note path:

   ```bash
   today_date=$(date +%Y-%m-%d)
   today_day=$(date +%A)
   today_year=$(date +%Y)
   note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"
   ```

   If the note does not exist, **skip this step** — do not fail because the comments were already posted. Mention the skip in the final report.

   If the note exists but has no `# Reviews` section, insert one after the `# Work Items` block:

   ```markdown
   # Reviews

   <!-- pr:post-findings appends reviewed PRs here -->

   ***
   ```

   Fetch PR title and author:

   ```bash
   gh pr view <pr_number> --json title,author --jq '"\(.title)|@\(.author.login)"'
   ```

   **Entry format** — each reviewed PR is one top-level list item under `# Reviews`; the comments posted in this run are an indented sub-list beneath it:

   ```markdown
   - [<owner>/<repo>#<pr_number>](<pr_url>) — <PR title> — @<author>
     - [<file>:<line>](<comment_url>) — <brief finding description>
     - [<file>:<line>](<comment_url>) — <brief finding description>
   ```

   - The PR line's link text is `<owner>/<repo>#<pr_number>` (e.g. `getditto/forge#887`), linked to `<pr_url>`.
   - Add one sub-bullet per posted finding. Its link text is `<file>:<line>` — the basename of the finding's `path` and its anchor `line`, e.g. `CalendarComponent.swift:209` — linked to that finding's captured `comment_url`. For a fallback/general comment, append ` (general)` to its sub-bullet.

   **Append rules:**

   - **PR already listed** (a `- [<owner>/<repo>#<pr_number>](` line exists under `# Reviews`): append new comment sub-bullets under that existing item instead of repeating the PR line.
   - **PR not listed:** insert the new PR item after `<!-- pr:post-findings appends reviewed PRs here -->`, following the next blank line. If that marker is absent, append at the end of the `# Reviews` section before its `***` separator.

   Make the daily-note update before reporting success. Use `apply_patch` to make the change. If the note is outside the active Codex workspace, request narrowly scoped write access to that note and retry; do not silently skip a note that exists. Re-read the `# Reviews` entry after editing. Verify that every captured `comment_url` appears in the updated entry.

7. Report posted and fallback comments with PR URL, plus daily-note status:

   ```text
   Posted N finding(s) to PR #<pr_number>:
     ✅ #1 — <brief description> (inline at <path>:<line>)
     ⚠️ #2 — <brief description> (general comment — line not in diff)
   <pr_url>

   Daily note: added <N> comment(s) under <owner>/<repo>#<pr_number> in # Reviews
   ```
