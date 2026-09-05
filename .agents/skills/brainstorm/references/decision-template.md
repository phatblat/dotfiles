# Decision document template

Conventional Docs (https://github.com/phatblat/conventional-docs) ships no decision
template of its own. These two shapes are this fork's convention — pick the one that
matches the repo's Artifact Location result in `~/.agents/skills/brainstorm/SKILL.md`.

Heading names follow MADR where MADR has an equivalent, so MADR-aware readers and
tooling recognize the file.

## Graduated shape — `docs/decisions/NNNN-slug.md`

```markdown
---
status: proposed
date: YYYY-MM-DD
decision-makers: [<name>]
---

# NNNN — <Title>

## Context and Problem Statement

<Why this is on the table now. The forces in play. What breaks if nothing changes.>

## Considered Options

### <Option name>

<One paragraph: what it is and how it behaves.>

- Pro: <…>
- Con: <…>

## Decision Outcome

<The chosen option, stated as a decision in one or two sentences, and why it beat the
others.>

## Consequences

<What this costs. What it forecloses. What has to change as a result.>

## Prototype Findings

<Omit this heading entirely unless a prototype ran. What was tried, what it proved or
disproved, and what changed in this Decision as a result. Prototype code is throwaway
and is not committed.>
```

## Small-repo shape — one section appended to `DECISIONS.md`

Same content one heading level deeper; status inline because there is no
per-decision frontmatter:

```markdown
## NNNN — <Title>

**Status:** proposed · **Date:** YYYY-MM-DD · **Decision-makers:** <name>

### Context and Problem Statement
### Considered Options
### Decision Outcome
### Consequences
### Prototype Findings
```

## Status values

- `proposed` — the spec, revisable in place (commit `decision: revise NNNN <what changed>`).
- `accepted` — frozen. Changing your mind is a new Decision that supersedes this one.
- `implemented` — the work shipped. This is a Conventional Docs addition to MADR's
  status set (`proposed` / `rejected` / `accepted` / `deprecated` / `superseded`).
- `superseded` — replaced; name the successor number in the body.

## Recording a status transition

- Graduated shape: update the frontmatter `status:` field.
- Small shape: update the inline `**Status:**` field.

Either way, the transition is committed with the matching event-commit subject from
`## Phases and Commit Gates` in the SKILL.md — never folded into an unrelated commit.
