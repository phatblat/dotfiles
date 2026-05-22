---
description: Create a PR for the current branch, or update the description if one already exists
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*), Skill
category: workflow
---

# Create or Update PR

Create a GitHub PR for the current branch. If a PR already exists, delegate to `/pr:update-desc` instead.

## Instructions

### 0. Load PR Style

Invoke the `pr-style` skill to load formatting conventions (title, body, labels, assignment, draft policy). Follow its rules for all subsequent steps.

### 1. Gather Context

Run a single combined command:

```bash
remote=$(git remote | head -1)
branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
echo "remote=${remote} branch=${branch} default=${default_branch}"
```

If `branch` equals `default_branch`, stop and report: "Cannot create a PR from the default branch (`${default_branch}`)."

### 2. Check for Existing PR

```bash
gh pr list --head "${branch}" --state open --json number,url,title --jq '.[0] | "\(.number)|\(.title)|\(.url)"'
```

- **PR exists**: Report "PR #N already exists" and invoke `/pr:update-desc` to update the description. Then stop.
- **No PR**: Continue to step 3.

### 3. Ensure Branch Is Pushed

Check if the remote branch exists:

```bash
git ls-remote --heads ${remote} ${branch}
```

If no remote branch, push with explicit refspec:

```bash
git push -u ${remote} ${branch}:${branch}
```

If remote branch exists, ensure local is up to date:

```bash
git push ${remote} ${branch}:${branch}
```

### 4. Collect Commit History

Get all commits on this branch since it diverged from the default branch:

```bash
git log --oneline ${default_branch}..HEAD
```

Also get the full diff stat:

```bash
git diff --stat ${default_branch}...HEAD
```

### 5. Generate PR Title and Description

Follow the `pr-style` skill for title format, body template, and guidelines.

### 6. Detect Labels

Scan the commit log from step 4 for conventional commit prefixes. Map them to GitHub labels per the `pr-style` skill label table. Collect all unique labels.

Present the proposed labels and ask the user to confirm or edit:

```
Proposed labels: enhancement, documentation
Confirm? [Y/n/edit]
```

### 7. Create the PR

```bash
gh pr create --draft --assignee @me --label "<confirmed labels>" --title "<title>" --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

If no labels were confirmed, omit the `--label` flag.

### 8. Report Result

Output:

```
Created PR #<number> (draft)
<pr_url>
Labels: <applied labels>
Assigned: @me
```
