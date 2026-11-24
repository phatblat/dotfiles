---
name: pr-style
description: PR formatting reference — title, body template, label mapping, assignment, and draft policy. Invoked by pr/create and pr/update-desc commands to ensure consistent PR formatting.
---

# PR Style Guide

## Title

`<type>(<scope>): <description>` — max 70 chars, imperative mood, no period.
Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build. Scope optional.

## Body Template

```markdown
<ticket refs — "Resolves ENG-1234" when the PR completely addresses the Linear ticket (tells Linear to close it on merge), or "Contributes to ENG-1234" when the PR is part of several PRs for the ticket. Omit if none.>
<stacked note — "Stacked on #42". Omit if not stacked.>

## Summary
<1-3 sentences — plain language, no jargon. Write as if explaining to someone outside the team: what problem does this solve, and what did you do about it? Avoid acronyms, internal tool names, and implementation details. Save those for the Changes section.>

## Changes
<bulleted list, grouped logically, imperative mood, no commit hashes>
```

Collapse trivial commits. Scannable in under 30 seconds.

## Labels

Auto-detect from commit prefixes: feat→enhancement, fix→bug, docs→documentation, chore/ci/build→maintenance, refactor→refactoring, test→testing, perf→performance.

Validate with `gh label list --json name --jq '.[].name'` — drop labels that don't exist in the repo. Auto-apply without confirmation.

## Flags

Always: `--draft --assignee @me`. Add `--add-label` with all validated labels.
