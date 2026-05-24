---
name: github-actions
description: |-
  Audit, fix, and generate GitHub Actions workflows with SHA-pinned action versions.
  Use when creating or editing workflow files, auditing action pinning, or when the user
  mentions "github actions", "workflow", "action pinning", "pin actions", "SHA pin",
  "supply chain", or asks about CI/CD in a GitHub repo.
---

# GitHub Actions Skill

Generate, audit, and fix GitHub Actions workflows following the conventions in the `github-actions` rule.

## When to Use

- Creating a new workflow file
- Editing an existing workflow
- User asks to audit or pin action versions
- User mentions supply chain security for CI/CD

## Audit: Check Pinning

### Step 1: Find Workflow Files

```bash
find .github -name '*.yml' -o -name '*.yaml' 2>/dev/null
```

### Step 2: Identify Unpinned Actions

Search for `uses:` lines where the version is NOT a 40-character hex SHA:

```bash
grep -n 'uses:' .github/workflows/*.yml | grep -v '[a-f0-9]\{40\}' | grep -v 'gha-pin-allow'
```

Exclude:
- Local actions (`uses: ./`)
- Lines with `# gha-pin-allow:` annotation

### Step 3: Report Findings

For each unpinned action, report:
- File and line number
- Current version (tag or branch)
- Whether it's a candidate for pinning or an exception

## Fix: Pin Actions to SHA

For each unpinned action that should be pinned:

### Step 1: Parse the Action Reference

Extract `owner/repo` and `tag` from `uses: owner/repo@tag`.

### Step 2: Resolve the SHA

```bash
# Try direct tag first
sha=$(gh api "repos/{owner}/{repo}/git/ref/tags/{tag}" --jq '.object.sha' 2>/dev/null)

# If it's an annotated tag, dereference to the commit
type=$(gh api "repos/{owner}/{repo}/git/tags/${sha}" --jq '.object.type' 2>/dev/null)
if [ "$type" = "commit" ]; then
    commit_sha=$(gh api "repos/{owner}/{repo}/git/tags/${sha}" --jq '.object.sha')
    sha="$commit_sha"
fi
```

### Step 3: Replace in File

Transform:
```yaml
uses: actions/checkout@v4
```
To:
```yaml
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

Preserve the original tag in the trailing comment for readability and update tooling.

### Step 4: Verify

Run the workflow syntax check if `actionlint` is available:

```bash
actionlint .github/workflows/<file>
```

## Generate: New Workflow

When creating a new workflow, always:

1. Pin all external actions to SHA (resolve at creation time)
2. Add `permissions:` block with minimal scopes
3. Set `timeout-minutes` on each job
4. Add `concurrency` group if triggered by push/PR

## Exception Handling

When encountering a `# gha-pin-allow:` annotation:
- Do NOT flag it as unpinned
- Do NOT attempt to resolve a SHA for it
- Include it in the audit report as "exempt" with the stated reason

When the user needs a linked-branch exception:
```yaml
uses: my-org/shared-action@feature-branch  # gha-pin-allow: linked-branch
```

Remind the user to pin it to a SHA once the linked work is merged.

## Do NOT

- Pin local/composite actions (`uses: ./path`) — they're in the same repo
- Remove existing `# gha-pin-allow:` annotations without asking
- Guess SHAs — always resolve them via the GitHub API
- Pin to a SHA without noting the original tag in the comment
