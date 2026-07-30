---
name: handoff
description: Create and commit a durable handoff document that gives a fresh agent the context and prompt to continue the current planning or implementation work. Use only when explicitly invoked as `$handoff` or when the user explicitly requests a handoff.
---

# handoff

Create a durable, committed handoff document for a fresh agent to resume the
current work in a new session. Treat it as a replacement for conversation
compaction: the document must let the next agent begin without access to this
chat.

## Rules

- Act immediately. Do **not** ask the user clarifying questions.
- Put unknowns, decisions requiring confirmation, and questions for the human
  in the handoff document under **Open Questions**. The next agent asks them
  only when they block progress.
- Capture facts from the repository and this session; distinguish facts from
  assumptions and recommendations.
- Do not include secrets, tokens, credentials, or unredacted sensitive command
  output.
- Commit only the handoff document. Do not stage, modify, stash, discard, or
  commit pre-existing user changes.

## Workflow

1. Inspect the current context in one command where possible:

   ```bash
   git rev-parse --show-toplevel && git branch --show-current && \
   git status --short --branch && echo "---DIFF---" && \
   git diff --stat && echo "---CACHED---" && git diff --cached --stat && \
   echo "---RECENT---" && git log --oneline -5
   ```

   Also inspect the relevant files, issue/PR/ticket context, commands run, and
   test results already established in this session. If the current directory
   is not a Git repository, write the document but report that it could not be
   committed.

2. Derive a concise lowercase-kebab-case topic from the work being handed off.
   Create `docs/handoffs/YYYY-MM-DD-<topic>.md`. If the topic is unclear, use
   `docs/handoffs/YYYY-MM-DD-session-handoff.md`; do not ask.

3. Write the document using the template below. Be specific: cite repository
   paths, branch names, commit SHAs, commands, and observed outcomes. Include
   only sections that have relevant content, except **Open Questions**,
   **Confidence**, and **Start Here**, which are always required.

   ```markdown
   # Handoff: <topic>

   **Created:** <ISO 8601 timestamp>
   **Repository:** `<absolute repository root>`
   **Branch:** `<branch>`
   **Base / HEAD:** `<base if known>` / `<HEAD SHA>`
   **Status:** <clean or exact modified/untracked files>

   ## Goal

   <The requested outcome and success criteria.>

   ## Start Here

   > You are continuing the work described in this handoff. First run the
   > verification commands in **Current State**, read the listed context files,
   > then execute **Recommended Next Steps**. Preserve the recorded decisions;
   > revisit them only if new evidence invalidates an assumption. Ask the human
   > only the blocking questions in **Open Questions**.

   ## Current State

   - **Completed:** <facts, including commits already made.>
   - **In progress:** <precise partial work and its state.>
   - **Working tree:** <which files are intentionally modified and why.>
   - **Verification:** <commands run and their exact pass/fail/not-run result.>
   - **Resume commands:**
     ```bash
     <safe commands to confirm branch, status, and relevant tests>
     ```

   ## Decisions Made

   | Decision | Rationale | Do not pursue |
   | --- | --- | --- |
   | <chosen direction> | <evidence or constraint> | <rejected paths and why> |

   ## Relevant Context

   - `<path>` — <why the next agent should read it.>
   - <Issue, PR, ticket, external reference, or prior commit> — <relevance.>

   ## Recommended Next Steps

   1. <small, ordered, independently verifiable action>
   2. <next action, including tests and commit boundaries where applicable>

   ## Open Questions

   - [ ] <Question for the human or a fact that must be verified; state the
     impact if unanswered.>

   ## Confidence

   **Plan completeness:** <high | medium | low> (<0–100>%).

   <What is known, what remains uncertain, and what evidence would increase
   confidence.>

   ## Estimate

   - **Scope:** <small | medium | large>
   - **Story points:** <number or range>
   - **Engineering time:** <range>
   - **Agent effort:** <approximate token range, if meaningful>
   - **Main risk:** <largest uncertainty or dependency>

   ## Suggested Agent Structure

   <Use one agent when the work is sequential or small. For parallelizable work,
   name each role, its bounded responsibility, dependencies, and integration
   order. State "Not warranted" when a team would add coordination overhead.>
   ```

4. Review the document for completeness, factual accuracy, sensitive data, and
   actionable next steps. Replace empty template fields with `Not applicable`
   or a concrete open question; do not leave placeholders.

5. Commit the document without touching other changes:

   ```bash
   git add -- "docs/handoffs/YYYY-MM-DD-<topic>.md"
   git commit -m "docs: Add <topic> handoff"
   ```

   If the commit fails because of a hook or repository state, keep the document
   written, report the failure and exact remediation, and do not alter unrelated
   changes.

6. Report the document path, commit SHA, confidence level, the first next step,
   and every unresolved question.
