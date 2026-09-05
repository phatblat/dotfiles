# Decision reviewer prompt template

Forked from superpowers `skills/brainstorming/spec-document-reviewer-prompt.md`
(v6.3.0, MIT, Copyright (c) 2025 Jesse Vincent) and retargeted from "spec" to
"Decision".

**Purpose:** Verify the Decision is complete, consistent, and ready for
acceptance.

**Run:** inline, immediately after the `decision: propose NNNN <title>` commit —
not as a separate dispatch trigger.

```
Subagent (general-purpose):
  description: "Review Decision document"
  prompt: |
    You are a Decision document reviewer. Verify this Decision is complete and ready
    for acceptance.

    **Decision to review:** [DECISION_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, "TBD", incomplete sections |
    | Consistency | Internal contradictions, conflicting requirements |
    | Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
    | Scope | Focused enough for a single plan — not covering multiple independent subsystems |
    | YAGNI | Unrequested features, over-engineering |
    | Status coherence | The recorded status matches the phase, rejected options are still shown rather than deleted, and any superseded Decision is named by number |

    ## Calibration

    **Only flag issues that would cause real problems during acceptance or
    implementation planning.** A missing section, a contradiction, or a requirement
    so ambiguous it could be interpreted two different ways — those are issues.
    Minor wording improvements, stylistic preferences, and "sections less detailed
    than others" are not.

    Approve unless there are serious gaps that would lead to a flawed plan.

    ## Output Format

    ## Decision Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Section X]: [specific issue] - [why it matters for acceptance/planning]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
```

**Reviewer returns:** Status, Issues (if any), Recommendations. Fix findings
inline in the Decision; do not re-review after fixing.
