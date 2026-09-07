# Plan: 2026-09-07-adopt-conventional-docs

Decision: `docs/decisions/2026-09-07-adopt-conventional-docs.md`

## Steps

- [x] Install the `conventional-docs` skill as a symlink at
      `.agents/skills/conventional-docs`, regenerate and commit its
      antigravity/cursor adapters
- [x] Write and accept the adoption decision record
- [x] Write this Plan
- [ ] Cache the todo list in `TODO.md`
- [ ] Write `docs/charter.md`, add `.adr-dir`, and update `AGENTS.md` with the
      Documentation Convention section and the `decision:`/`plan:`/`todo:`
      event vocabulary
- [ ] Sync `TODO.md`, then delete `PLAN.md` (`plan: done`) and `TODO.md`
      (`todo: clear`)

## Verification

- `bash scripts/check-symlinks.sh .agents/skills/conventional-docs` exits 0
- `just harness-check` reports no staleness attributable to
  `conventional-docs` (pre-existing, unrelated probe-version drift in
  `docs/agent-harnesses.*` and `docs/harness/*.md` is out of scope)
- `just check-spelling` passes on the new markdown
- `git log --oneline` shows single-artifact `decision:`/`plan:`/`todo:`
  commits; dropping every `plan:`/`todo:` commit leaves the tree identical
- `docs/charter.md`, `.adr-dir`, and `docs/decisions/` exist; `PLAN.md` and
  `TODO.md` are gone at the end

## Status

Decision accepted; installing the skill, writing the Charter, and wiring
`AGENTS.md` in this session. Todo cache and cleanup commits follow in the
same session.
