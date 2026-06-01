---
description: Update the PR description for the current branch
model: sonnet
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*), Skill
category: workflow
---

# Update PR Description

Regenerate and update the GitHub PR description for the current branch based on all commits in the PR.

## Instructions

### 0. Load PR Style

Invoke the `pr-style` skill to load formatting conventions for the PR body.

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

Follow the `pr-style` skill for body template and guidelines.

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
