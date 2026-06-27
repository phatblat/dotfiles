---
name: pr-create
description: Create or update a GitHub pull request for the current branch. Use when the user invokes `$pr-create`, asks to create/open a PR, or wants the current branch pushed and described as a draft PR.
---

# pr-create

Create a GitHub PR for the current branch. If a PR already exists, use `$pr-update-desc` to refresh its description instead.

## Workflow

### 0. Load PR style

Use the `pr-style` skill for title format, body template, labels, assignment, and draft policy. Follow those rules for the PR title, body, and label handling.

### 1. Gather context

Run:

```bash
remote=$(git remote | head -1)
branch=$(git branch --show-current)
default_branch=$(git symbolic-ref refs/remotes/${remote}/HEAD 2>/dev/null | sed "s|refs/remotes/${remote}/||" || echo "main")
echo "remote=${remote} branch=${branch} default=${default_branch}"
```

If `branch` equals `default_branch`, stop and report:

```text
Cannot create a PR from the default branch (`<default_branch>`).
```

### 2. Check for an existing PR

Run:

```bash
gh pr list --head "${branch}" --state open --json number,url,title --jq '.[0] | "\(.number)|\(.title)|\(.url)"'
```

- If a PR exists, report `PR #<number> already exists`, use `$pr-update-desc` to update the description, then stop.
- If no PR exists, continue.

### 3. Ensure the branch is pushed

Check whether the remote branch exists:

```bash
git ls-remote --heads "${remote}" "${branch}"
```

If no remote branch exists, push with an explicit refspec:

```bash
git push -u "${remote}" "${branch}:${branch}"
```

If the remote branch exists, push the current local branch to it:

```bash
git push "${remote}" "${branch}:${branch}"
```

### 4. Collect PR source material

Get branch commits:

```bash
git log --oneline "${default_branch}..HEAD"
```

Get the high-level diff:

```bash
git diff --stat "${default_branch}...HEAD"
```

Use these outputs with `pr-style` to generate the PR title and body.

### 5. Detect labels

Map conventional commit prefixes in the branch log using the `pr-style` label table. Validate candidate labels against the repo:

```bash
gh label list --json name --jq '.[].name'
```

Apply only labels that exist. If no valid labels exist, omit label flags.

### 6. Create the draft PR

Create a draft PR assigned to the current GitHub user:

```bash
gh pr create --draft --assignee @me --title "<title>" --body "$(cat <<'EOF'
<generated description>
EOF
)"
```

If valid labels were detected, include them with repeated `--label "<label>"` flags.

### 7. Report result

Output:

```text
Created PR #<number> (draft)
<pr_url>
Labels: <applied labels or none>
Assigned: @me
```
