---
id: 001
title: Self-improving harness loop — safety substrate first
category: harness-config
status: approved
approved_by: phatblat
approved_at: 2026-08-12
auto_implement: false
evidence:
  - signal: ruleset-bypass-actor
    count: 1
    window: 2026-08-11/2026-08-11
  - signal: control-plane-writable
    count: 7
    window: 2026-08-11/2026-08-11
  - signal: generated-file-undetectable-by-header
    count: 4
    window: 2026-08-11/2026-08-11
targets:
  sources:
    - ".agents/harness/hooks/safety.py"
    - "scripts/agent-harnesses.py"
    - ".github/workflows/lint.yml"
    - ".github/workflows/agent-harness-parity.yml"
    - ".github/workflows/human-approval.yml"
    - "tests/agent-harnesses.bats"
  generated: []
verification: "HOME=$PWD just check"
rollback: "git revert <sha>"
---

## Problem

The goal is a loop that watches how the harness underperforms, proposes units of
work, and — once a human approves — implements them behind a pull request. Three
findings from designing it say the loop cannot be built yet, because the controls
it would run under do not hold.

**The pull request gate does not exist.** Ruleset 13542903 ("Protect main")
carries `bypass_actors: [{actor_id: 5, actor_type: RepositoryRole, bypass_mode:
always}]`. Role 5 is admin; the repository owner is an admin, and any agent runs
with the owner's token. Alongside that: `required_approving_review_count: 0`, and
no `required_status_checks` rule at all, so the 32 bats files in `tests/` do not
gate a merge. Ruleset 13416093 ("Copilot Reviews") sets
`review_draft_pull_requests: false`, so the draft pull requests a loop would open
receive no machine review either. "A human reviews and merges" is a convention,
not a control.

**The guard does not defend the guard.** `PROTECTED_PATHS` in
`.agents/harness/hooks/safety.py` lists credentials only. Verified by executing
the policy:

```
guard --tool write --path .agents/harness/hooks/safety.py  → allow
guard --tool bash --command "gh pr merge --admin --squash" → allow
guard --tool bash --command "git push --force phatblat main" → allow
```

An agent whose stated job is "tweak harness configuration" has write access to
its own kill switch, and a plausible reason to use it the first time the guard
blocks something.

**Generated files cannot be detected by grepping the header.** `MANAGED_HEADER`
is a comment, so the four generated JSON artifacts — `docs/agent-harnesses.json`,
`.pi/agent/agents.json`, and both adapter `plugin.json` files — carry no marker.
An agent editing one loses the work at the next `just harness-generate`, with no
warning. `render_all()` is the only authoritative registry, and it is far too
expensive to call on the guard hot path, which defers imports specifically to
stay near 0.06s per call.

These are pre-existing conditions. They are true today, with or without the loop.

## Proposed change

Ship the safety substrate only. No scheduler, no model calls, no tracker. Each
item stands on its own if the loop is never built.

1. **Control-plane paths become human-only.** A `CONTROL_PLANE_PATHS` pattern in
   `safety.py` denies agent writes to the guard, the generator, and the per-harness
   guard shims, with a message that says to edit them by hand. Distinct from
   `PROTECTED_PATHS` so the denial reason stays honest — these are not credentials.

2. **A generated-path manifest.** `render_all()` emits
   `.agents/harness/generated-paths.json`, mapping every generated path to its
   producer and its hand-written source. Being a `render_all()` output, it is
   parity-checked by the existing `just harness-check` and cannot drift.

3. **A `provenance` subcommand** reports `generated` / `source` / `generator` /
   `other` for a path, reading the manifest rather than re-rendering.

4. **A guard rule** denies `write`/`edit` to any path in the manifest, naming the
   source to edit instead. This runs on the existing hot path and is therefore
   already wired into all seven harnesses.

5. **Workflow checks always report.** `lint`, `test`, and `parity` are currently
   filtered at the `on:` trigger, so a pull request touching none of their paths
   produces no check at all. Making them required in that state would deadlock
   every such pull request. The filter moves into the jobs: the workflow always
   runs, and the expensive step is skipped when irrelevant. `.agents/skills/**`
   joins the parity filter — it is a generator input (`SKILL_SOURCE`) that today
   triggers no parity signal.

6. **A `human-approval` check.** Loop-authored pull requests carry a
   `loop-authored` label; the check fails until a human adds `human-approved`.
   Applying a label is the human gate, and the ruleset makes it non-bypassable.
   A review count of 1 does not work here — GitHub disables self-approval, and a
   solo maintainer would deadlock.

## Out of scope

Not in this change, deliberately:

- **The loop itself.** No detector, no scheduler, no synthesis, no specs written
  by a model. Whether recurring harness-attributable friction exists here is an
  untested premise; the next step is to measure it, not to build machinery to act
  on it.
- **The three `pi-*` plugins.** All peer-depend on `@earendil-works/*` or
  `@mariozechner/*`; this harness is `@oh-my-pi/*`, distributed as a compiled
  binary. `@askjo/pi-reflect` additionally auto-commits transcript-derived content
  to git, which in a public repository rooted at `$HOME` is the highest-risk item
  considered. Revisit `pi-experiences` only after the loop exists.
- **aven.** Justified only for the private pre-approval stage, which does not
  exist yet. Adopting it now would create a tracker with nothing to track.
- **The ruleset edits themselves.** `bypass_actors` and `required_status_checks`
  are applied through the GitHub API, not this repository, and must land *after*
  the workflow changes reach `main` — otherwise the new required checks block
  every pull request. Category `rulesets` is `never`: a human runs them.

## Verification

`HOME=$PWD just check` — lint, spelling, harness parity, and bats.

New bats coverage asserts the guard denies a write to a generated file, denies a
write to `safety.py`, and that every key in `generated-paths.json` resolves.

The ruleset changes are verified separately, after merge:

```
gh api repos/phatblat/dotfiles/rulesets/13542903 --jq '.bypass_actors'   # → []
gh pr checks <pr>                                                        # → lint, test, parity, human-approval
```
