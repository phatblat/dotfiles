# Decision document template

Conventional Docs (https://github.com/phatblat/conventional-docs) defines the
skeleton below in its own `SKILL.md`; this file exists only to layer in this
fork's one addition — the `## Prototype Findings` section for the brainstorm
skill's `## Prototype` phase — and to restate the status values for quick
reference during review.

Every Decision lives at `docs/decisions/YYYY-MM-DD-slug.md`. There is no
single-file form and no graduation step: this is the only location.

## Structure

Use exactly this skeleton, H2 sections in this order:

```markdown
# <Decision title>

## Issue

<The problem requiring a decision, with links to the motivating issue and PRs.
If this decision extends another, the first sentence is `This decision extends
[YYYY-MM-DD-slug](./YYYY-MM-DD-slug.md).` and nothing from that decision is
restated.>

## Status

This is a proposal that is **awaiting review**.

## Assumptions and Constraints

- <Facts bounding the choice: environment, compatibility guarantees, prior
  decisions. For a change to a public surface, state the compatibility
  guarantee it has to keep here.>

## Argument

<Why the chosen direction beats the alternatives. Name any alternative that
shapes the choice, with its verdict (**Chosen.** / **Rejected.**), and reserve
full reasoning for Positions. `N/A` is acceptable when the constraints make the
decision self-evident.>

## Architectural Decision

<The decision itself, as numbered clauses a reviewer can point at. Include code
or YAML only where it pins down a contract — a field name, a struct variant,
one representative manifest — never to reproduce the implementation.>

## Prototype Findings

<Omit this heading entirely unless brainstorm's `## Prototype` phase ran. What
was tried, what it proved or disproved, and what changed in this Decision as a
result. Prototype code is throwaway and is not committed. This section is this
fork's addition — Conventional Docs itself does not define it — and is
positioned after Architectural Decision so it reads as evidence for the
decision already stated, not as a new claim.>

## Positions

<Alternatives considered and rejected, each with its reason, or `N/A`.>
```

Optional sections, in position (from Conventional Docs):

- `## Consequences` — after Architectural Decision / Prototype Findings,
  before Positions: rollout order, breaking changes, migration burden,
  follow-up documentation owed.
- `## References` — after Positions: bulleted links with `—` descriptions
  (tracking issue, implementation PRs, related decisions, external specs).
- `## Errata` — last, after References: append-only corrections and
  supersession pointers, added only once the record is frozen.

## Status values

A record has four states and moves through them in one direction:
**draft → proposed → accepted | rejected**. Each transition is a commit, and
`## Status` carries exactly one line:

- **draft** (`decision: draft <id>`) — `This is a **draft**; it is not ready
  for review.`
- **proposed** (`decision: propose <id>`) — `This is a proposal that is
  **awaiting review**.` This is the spec; revise it in place and commit
  `decision: revise <id> <what changed>`.
- **accepted** (`decision: accept <id>`) — `This is a proposal that is
  **accepted**.` Frozen: `accept` is the last write to the record's body.
  Changing your mind is a new Decision that supersedes this one — stated in
  the superseding record's Issue and as an Errata entry here, with this
  record's status unchanged.
- **rejected** (`decision: reject <id>`) — `This proposal was **rejected**.`
  A rejected record stays in the log.

There is no `implemented`, `superseded`, or `deprecated` status — that is
MADR's set, not Conventional Docs'. What shipped is `CHANGELOG.md`'s question
(the `recording-changes` skill), and `plan: done <id>` already announces that
an accepted decision's work is finished.

## Recording a status transition

Update the `## Status` line to the exact sentence above and commit with the
matching event-commit subject from `## Phases and Commit Gates` in
`brainstorm`'s `SKILL.md` — never folded into an unrelated commit.
