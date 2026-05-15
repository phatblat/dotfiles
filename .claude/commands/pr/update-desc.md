---
description: Update the PR description for the current branch
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*)
category: workflow
---

# Update PR Description

Regenerate and update the GitHub PR description for the current branch based on all commits in the PR.

## Instructions

### 1. Gather Context

Run a single combined command:

```bash
remote=$(git remote | head -1)
branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
echo "remote=${remote} branch=${branch} default=${default_branch}"
```

### 2. Find the PR

```bash
gh pr view --json number,url,title,body --jq '"\(.number)|\(.title)|\(.url)"'
```

If no PR exists for the current branch, stop and report: "No open PR found for branch `${branch}`."

### 3. Collect Commit History

Get all commits on this branch since it diverged from the default branch:

```bash
git log --oneline ${default_branch}..HEAD
```

Also get the full diff stat for a high-level summary of what changed:

```bash
git diff --stat ${default_branch}...HEAD
```

### 4. Generate PR Description

Analyze the commits and diff stat to produce a description with this structure:

```markdown
## Summary
<1-3 sentence overview of what this branch accomplishes>

## Changes
<bulleted list of meaningful changes, grouped logically — not a 1:1 commit echo>

## Files Changed
<bulleted list of key files/areas touched, with brief context>
```

Guidelines:
- Collapse trivial/chore commits (typo fixes, formatting) into the broader change they support
- Group related commits into a single bullet rather than listing each commit separately
- Use imperative mood ("Add X", "Fix Y", "Update Z")
- Keep it concise — the description should be scannable in under 30 seconds
- Do not include commit hashes in the description

### 5. Update the PR

```bash
gh pr edit --body "<generated description>"
```

Use a HEREDOC to pass the body to preserve formatting:

```bash
gh pr edit --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

### 6. Report Result

Output:

```
✅ Updated PR #<number> description
<pr_url>
```
