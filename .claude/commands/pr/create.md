---
description: Create a PR for the current branch, or update the description if one already exists
allowed-tools: Bash(git:*), Bash(gh:*), Bash(date:*), Skill
category: workflow
---

# Create or Update PR

Create a GitHub PR for the current branch. If a PR already exists, delegate to `/pr:update-desc` instead.

## Instructions

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

**Title**: Derive from the branch purpose. Use conventional commit style matching the project (e.g., `feat:`, `fix:`, `chore:`). Keep under 70 characters.

**Description**: Analyze the commits and diff stat to produce:

```markdown
## Summary
<1-3 sentence overview of what this branch accomplishes>

## Changes
<bulleted list of meaningful changes, grouped logically — not a 1:1 commit echo>

## Files Changed
<bulleted list of key files/areas touched, with brief context>
```

Guidelines:
- Collapse trivial/chore commits into the broader change they support
- Group related commits into a single bullet
- Use imperative mood ("Add X", "Fix Y", "Update Z")
- Keep it concise — scannable in under 30 seconds
- Do not include commit hashes

### 6. Create the PR

```bash
gh pr create --draft --title "<title>" --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

Always create as draft. The user will mark it ready when appropriate.

### 7. Report Result

Output:

```
✅ Created PR #<number> (draft)
<pr_url>
```
