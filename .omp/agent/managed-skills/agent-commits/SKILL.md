---
name: agent-commits
description: "Write commit messages under the agent-commits convention - a Conventional Commits fork with no chore catch-all, intent-only type tokens, facts in trailers, and legally-grounded AI provenance (Assisted-by, never Co-authored-by). Use when composing a commit in a repo whose commitlint.config.js extends agent-commits, when deciding between feat/fix/refactor/perf, or when recording AI participation."
---

# agent-commits

A commit convention for repositories where humans and AI agents both write code.
Conventional-Commits-compatible grammar; different type set and semantics.

## The one idea

**The type token holds intent. Facts go in trailers.**

Conventional Commits puts a *fact* into a slot that holds one value. "Bumps
axios," "patches a CVE," "changes runtime behavior" can all be true at once — so
you discard two facts, or you write `chore:`. `chore` is not a gap in the
taxonomy, it is overflow.

- **Intent** — why the commit exists. Exactly one. → the type token
- **Facts** — what it touches. Unbounded. → trailers
- **Release impact** — derived from type + `!`. Never authored.

## Grammar

```
<type>[(<scope>)][!]: <subject>

[body — explain why, not what]

[trailers]
```

## Types — 12, no catch-all

Read top to bottom, stop at the first match.

| Tier | Type | Fires when |
|---|---|---|
| meta | `release` | version bump, changelog cut, tag prep |
| observable | `security` | remediates a **named** vulnerability → needs `Advisory:` |
| | `feat` | adds a capability a consumer can reach |
| | `fix` | corrects behavior that contradicted a **stated contract** |
| | `perf` | same output, **measured** resource change |
| supply | `deps` | moves the resolved dependency graph → needs `Bumps:` |
| internal | `refactor` | changes product source, no observable delta |
| | `build` | how the artifact is produced or validated |
| | `ci` | CI workflow config |
| | `test` | test code only |
| | `docs` | prose for human readers |
| | `ignore` | diff touches **only** ignore-family files |

**Retired:** `chore` (use a specific type), `style` (→ `refactor` or `build`),
`revert` (→ original type + `Reverts:` trailer).

If nothing fits, the commit is doing two things. **Split it.** A subject with
"and" or a comma-list is the tell.

## Decision rules — mechanical, not judgment

**Rule N — `feat` vs `fix`**
Did the parent's docs, type signature, or tests already claim the behavior
existed? Broken promise → `fix`. Nothing claimed it → `feat`.

**Rule F — `fix` vs `refactor`**
Does the commit add/change a test expectation that **fails against the parent
commit**? Yes → `fix`. No → `refactor`. This is a runnable experiment, not
introspection. If you can't write that test, you don't know that you fixed
anything.

**Rule P — `perf`**
Requires a before/after measurement in the body. `perf` without a number is
`refactor` with a hope. The linter enforces this.

**Rule I — `ignore`**
Fires only when the diff is ignore-files-only. If an ignore edit rides along
with real work, type by dominant intent — adding `target/` to `.gitignore`
while creating the Cargo project is part of creating the Cargo project.

**Precedence when two types both fit**
Consumer-observable beats internal. Named-vulnerability beats dependency-bump
beats behavior-fix. Put the winner in the token, the loser in `Also:`.
Never discard the fact.

## Trailers

| Trailer | Required on |
|---|---|
| `Bumps: <pkg> <from> -> <to>` | `deps` |
| `Advisory: <id>` | `security` |
| `Generator: <tool>/<version>` | machine-produced output |
| `Reverts: <sha>` | replaces the `revert` type |
| `Also: <type>` | optional — the fact that lost the tiebreak |
| `Assisted-by: <model> <harness>/<ver> mode=<m>` | AI-assisted commits |
| `Reviewed-by:` / `Tested-by:` | optional; **absence is meaningful** |
| `Signed-off-by:` | humans only — never emit as an agent |

## Provenance — read this before attributing AI work

**Never write `Co-authored-by:` naming an AI.** U.S. Copyright Office guidance
(88 FR 16190) states applicants "should not list an AI technology or the company
that provided it as an author or co-author." The Linux kernel reached the same
conclusion independently: AI agents MUST NOT add `Signed-off-by`, and assistance
is recorded with `Assisted-by:`. The linter rejects AI co-authorship.

```
Assisted-by: claude-opus-4-6 claude-code/2.1.4 mode=autonomous
```

- `suggested` — agent proposed; a human applied each edit
- `supervised` — agent applied; a human approved each edit
- `autonomous` — agent applied and committed with no per-edit approval

The **author** is always the accountable human. `mode` is a fact about how the
harness ran, not a self-assessment of quality.

**Absence encodes absence.** There is no `Reviewed-by: none`. A field whose most
common value is "nothing happened" gets filled in reflexively and stops being
read.

## Worked examples

Clean feature:
```
feat(auth): add WebAuthn passkey enrolment

Adds second-factor enrolment backed by the WebAuthn Level 2 registration
ceremony. Existing TOTP enrolment is unchanged.

Reviewed-by: Dana Ortiz <dana@example.com>
```

Agent-authored fix:
```
fix(parser): reject trailing commas in strict mode

strictMode:true still accepted `[1,2,]`, diverging from the ECMA-404
grammar the flag claims to enforce.

Assisted-by: claude-opus-4-6 claude-code/2.1.4 mode=autonomous
Tested-by: ci/unit
```

The hard case — dependency bump that is also a CVE patch and breaking:
```
security(axios)!: upgrade to 1.8.4, patching SSRF via absolute baseURL

axios <1.8.2 resolves an absolute `url` against `baseURL`, letting a
caller-controlled path escape the configured host. The upgrade also
changes default paramsSerializer behaviour for array params.

Bumps: axios 0.27.2 -> 1.8.4
Advisory: GHSA-jwcz-9h9m-zp5q (CVE-2025-27152)
```
Three facts (`Bumps`, `Advisory`, `!`), one intent (`security`). Release derives
to major from `!`, not from the type.

Ignore:
```
ignore: Python virtualenv and bytecode artifacts
```

Breaking change with no product-source change — inexpressible in plain CC:
```
build!: require Node 22

The published bundle now emits `using` declarations, which Node 20
cannot parse. CI matrix drops 18.x and 20.x.
```

## Before committing

1. Does the subject describe **one** intent? If it has "and", split.
2. Is the type the *first* match in the cascade, not the most flattering?
3. Are required trailers present (`deps`→`Bumps:`, `security`→`Advisory:`)?
4. If AI-assisted: `Assisted-by:`, never `Co-authored-by:`.
5. Does `!` reflect whether a consumer must change something?

## Verify

```bash
echo "$MSG" | bunx commitlint          # message layer
```

commitlint sees only the message. Path rules (Rule I) and diff rules (Rule F)
need a separate diff-aware check.

## Reference

- `docs/type-taxonomy.md` — verdicts, evidence, open questions
- `docs/examples.md` — cookbook with ~80 real mined commits
- `docs/ai-authorship-rulings.md` — the legal basis for the provenance design
