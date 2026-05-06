---
name: linear-create
description: Create a well-structured Linear issue with context, labels, and an implementation plan. Use when the user asks to create, file, or log a Linear ticket/issue.
disable-model-invocation: true
argument-hint: [description of the issue]
---

# Create a Linear Issue

Create a new Linear issue following the instructions below.

## Setup

1. **Team**: Always use `ENG`.
2. **Assignee**: Always set to `me`.

## Gathering context

Before creating the issue, ensure you have enough information. If the user's request is vague, ask clarifying questions. You need at minimum:

- A clear understanding of what needs to be done and why
- Enough technical context to write an implementation plan

If the user provides a **project** or **milestone**, include them. Do not guess — only set these if explicitly provided.

## Labels

Choose appropriate labels based on the nature of the work. Fetch available labels for the ENG team and select the ones that best match. Apply multiple labels if relevant (e.g., a frontend bug might get both a "Bug" and "Frontend" label).

## Title

Write a concise, descriptive title. It should make sense at a glance in a list of issues.

## Description

Structure the issue description in **two sections**:

### Context section

Write 2-4 paragraphs explaining the what and why in plain language. Assume this will be read by a PM or someone non-technical. Cover:

- What is the current behavior or gap?
- What is the desired outcome?
- Why does this matter? (user impact, business value, unblocking other work, etc.)
- Any relevant background or constraints

### Implementation Plan section

Write a detailed, step-by-step plan that a junior developer could pick up and execute. Where relevant, include:

- Specific files or modules to modify/create
- Key functions, types, or components involved
- Database changes (migrations, new columns/tables)
- API changes (new endpoints, modified request/response shapes)
- Frontend changes (new components, updated views)
- Testing approach (what to test, how)
- Edge cases or gotchas to watch out for

Only include subsections that are relevant to the work — skip areas that aren't affected.

## Procedure

1. Fetch available labels for the ENG team.
2. If the user mentioned a project, look it up.
3. Research the codebase as needed to write an accurate implementation plan — read relevant files, search for existing patterns, understand the current state.
4. Create the issue with: title, team (`ENG`), assignee (`me`), labels, description, and optionally project, milestone, priority, and estimate.
5. Report back the issue identifier (e.g., ENG-XXX) and a brief summary.
