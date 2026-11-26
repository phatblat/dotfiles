# Make shared skill symlinks resolve inside the checkout

Priority: Low

## Problem

Five tracked links under `.agents/skills` (`authoring-skills`, `conventional-docs`, `recording-changes`, `semantic-versioning`, `setup-phatblat-skills`) point at `../../dev/agents/…`. That target resolves from `~/.agents/skills` but not from `~/dev/dotfiles/.agents/skills`. crush and Antigravity both scan the project-relative root, so inside this checkout they see five broken entries.

## Outcome

Every entry under `.agents/skills` resolves from both `~/.agents/skills` and the checkout's `.agents/skills`.

## Notes

- One relative target cannot satisfy both depths. The options are absolute targets or vendoring the skills.
