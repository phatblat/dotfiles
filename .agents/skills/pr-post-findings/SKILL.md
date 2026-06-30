---
name: pr-post-findings
description: Post findings from the most recent review output as inline GitHub PR comments. Use when invoked as `$pr-post-findings` or when the user asks to post review findings to the current PR.
---

# pr-post-findings

Post findings from the most recent review or code-review output in the conversation as inline comments on the current PR.

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

5. If inline posting fails because the line is not in the diff, fall back to:

   ```bash
   gh pr comment <pr_number> --body "<description>\n\n_Originally at: <url>_"
   ```

6. Report posted and fallback comments with PR URL.
