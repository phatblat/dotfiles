# Specs

One file per unit of harness work. A spec is a **rejection interface**: it exists
so a change can be killed in thirty seconds of reading, before anyone spends
tokens building it. If a spec takes longer to read than the diff would, skip the
spec and write the diff.

## When a spec is worth writing

- The change touches more than one harness, or the generator.
- A wrong guess is expensive to unwind.
- The work will be implemented by an agent that did not participate in the
  decision.

Anything under a screenful of mechanically verifiable diff (`just check` passes
or it does not) does not need one.

## Lifecycle

```
draft ──→ approved ──→ implementing ──→ in-review ──→ merged
   └──────→ rejected
```

Drafts live outside this repository (the repo is public, and a draft may quote
paths, hostnames, or errors from unrelated work). A spec is written here only
once it has been read and approved by a human — the approval boundary and the
redaction boundary are the same line.

## Categories

`category` decides how much autonomy an implementer has. The authoritative list
is `.agents/harness/self-improve-policy.json`; the summary:

| Tier | Categories | Autonomy |
| --- | --- | --- |
| auto | `docs`, `ci-path-filter`, `tool-version-bump` | May implement and open a draft PR |
| propose | `harness-config`, `build-script`, `tool-install` | May implement; the diff needs review, not just the spec |
| never | `generator-change`, `safety-policy`, `gitignore`, `git-filters`, `rulesets` | Describe the problem only. A human writes the code |

The `never` tier is not a preference. Those paths decide what everything else is
allowed to do, so an agent that can edit them can grant itself the rest.

## Frontmatter

```yaml
---
id: 004
title: Short imperative phrase
category: harness-config
status: approved
approved_by: phatblat
approved_at: 2026-08-12
auto_implement: false
evidence:
  - signal: parity-stale-no-ci
    count: 4
    window: 2026-07-14/2026-08-11
targets:
  sources: [".github/workflows/agent-harness-parity.yml"]
  generated: []      # must stay empty unless category is generator-change
verification: "HOME=$PWD just check"
rollback: "git revert <sha>"
---
```

`targets.generated` is the self-check. Before implementing, run
`python3 scripts/agent-harnesses.py provenance --path <p>` on every entry in
`targets.sources`; if any resolves to `generated`, the spec is wrong and the
work stops. Generated files are overwritten by the next `just harness-generate`,
so editing one silently discards the change.

## Body

Four headings, in this order. Keep it short.

```markdown
## Problem
## Proposed change
## Out of scope
## Verification
```
