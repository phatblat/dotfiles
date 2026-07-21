---
description: Prevent accidental PR merges — only merge when explicitly commanded
---

# PR Merge Safety

**NEVER run `gh pr merge`, `git merge` into main/master, or any equivalent without the user invoking `/pr:merge`.**

This includes:
- Merging as part of a "ship it" or "finish up" request
- Merging after CI passes
- Merging at the end of a workflow (e.g., branch-finish, linear:plan)
- Suggesting merge and then doing it in the same turn

If a workflow or task would naturally end with a merge, stop before the merge and tell the user to run `/pr:merge` when ready.
