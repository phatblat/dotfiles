---
name: pr-style
description: PR formatting reference — title, body template, label mapping, assignment, and draft policy. Invoked by pr/create and pr/update-desc commands to ensure consistent PR formatting.
---

# PR Style Guide

Reference skill defining pull request conventions. Invoked by PR commands — follow these rules when generating PR titles, descriptions, labels, and metadata.

## Title

- Conventional commit format: `<type>(<scope>): <description>`
- Max 70 characters
- Imperative mood, no trailing period
- Scope is optional — include when the change targets a specific area
- Valid types: feat, fix, docs, style, refactor, perf, test, chore, ci, build

## Body Template

```markdown
<ticket references, if any — e.g. "Closes ENG-1234" or "Refs ENG-1234, ENG-5678">
<stacked PR note, if any — e.g. "Stacked on #42" or "Base: #42">

## Summary
<1-3 sentence overview of what this branch accomplishes>

## Changes
<bulleted list of meaningful changes, grouped logically>
```

### Preamble Lines

The first two lines before `## Summary` are optional and appear without headers:

1. **Ticket references** — Linear tickets, GitHub issues, or other tracker links associated with this work. Use `Closes` for tickets resolved by this PR, `Refs` for related tickets. Omit entirely for personal repos or work with no ticket.
2. **Stacked PR relationship** — If this PR depends on or is stacked on another PR, note it (e.g. `Stacked on #42`). Omit if not stacked.

Include a blank line between the preamble and `## Summary`.

### Body Rules

- Collapse trivial/chore commits into the broader change they support
- Group related commits into a single bullet
- Use imperative mood ("Add X", "Fix Y", "Update Z")
- Scannable in under 30 seconds
- No commit hashes

## Labels

Auto-detect from conventional commit prefixes found in the branch commits:

| Commit prefix          | GitHub label    |
|------------------------|-----------------|
| `feat`                 | `enhancement`   |
| `fix`                  | `bug`           |
| `docs`                 | `documentation` |
| `chore`, `ci`, `build` | `maintenance`   |
| `refactor`             | `refactoring`   |
| `test`                 | `testing`       |
| `perf`                 | `performance`   |

If commits span multiple types, include all matching labels.

### Label Validation

Before proposing labels, fetch the repo's actual labels:

```bash
gh label list --json name --jq '.[].name'
```

Only propose labels that exist in the repo. Silently drop any mapped label that doesn't exist.

### Label Override

After auto-detection and validation, present proposed labels and ask the user to confirm or change:

```
Proposed labels: enhancement, documentation
Confirm? [Y/n/edit]
```

Only apply labels after confirmation. If the user edits, use their choices exactly.

## Assignment

Always self-assign: `--assignee @me`

## Draft Status

Always create as draft: `--draft`

## gh pr create Flags

```bash
gh pr create \
  --draft \
  --assignee @me \
  --label "<comma-separated labels>" \
  --title "<title>" \
  --body "$(cat <<'EOF'
<body>
EOF
)"
```

If no labels are confirmed, omit the `--label` flag entirely.
