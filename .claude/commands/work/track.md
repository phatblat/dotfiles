---
description: Track a Linear ticket or GitHub PR in today's daily note
argument_hint: "<TICKET-ID or PR-URL> [notes]"
allowed-tools:
  - Bash(linear:*)
  - Bash(gh:*)
  - Bash(date:*)
  - Bash(grep:*)
  - Read
  - Edit
  - mcp__linear__get_issue
  - mcp__linear__list_issue_statuses
category: workflow
---

# Track Work Item

Add or update a Linear ticket or GitHub PR in today's daily note. Each item gets a persistent H2 section with inline fields and a timestamped activity log.

## Arguments

`$ARGUMENTS`

Parse arguments:

- **Item identifier** (required): Either a Linear ticket ID (e.g., `DXO-71`, `DEVX-943`) or a GitHub PR URL (e.g., `https://github.com/getditto/ditto/pull/23274`) or shorthand (`getditto/ditto#23274`)
- **Notes** (optional): Freeform text describing what you're doing. If omitted, generate a brief note from the item's current state.

If just a number is provided, assume it's a DXO ticket (prepend `DXO-`).

## Step 1: Locate Today's Note

```bash
today_date=$(date +%Y-%m-%d)
today_day=$(date +%A)
today_year=$(date +%Y)
note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"
```

If the note doesn't exist, tell the user to run `/work:start` first.

## Step 2: Fetch Item Details

### For Linear Tickets

Use `mcp__linear__get_issue` to fetch the ticket. Extract:

- **Identifier** (e.g., `DXO-71`)
- **Title**
- **State** (e.g., `In Progress`, `In Review`, `Done`)
- **URL** (construct as `https://linear.app/ditto/issue/<ID-LOWERCASE>`)

Also check for associated PRs by reading the ticket description and comments for GitHub PR links.

### For GitHub PRs

```bash
gh pr view <PR-URL-or-NUMBER> --json number,title,state,url,repository,headRefName --repo <owner/repo>
```

Extract number, title, state, URL. Check if the PR description references a Linear ticket (look for patterns like `DXO-\d+`, `DEVX-\d+`, or `linear.app/ditto/issue/` URLs).

If a linked Linear ticket is found, also fetch its details to populate the `ticket::` field.

## Step 3: Check for Existing Section

Read today's note and search for an existing section for this item:

```bash
grep -nE "^## .*${TICKET_ID}( |$)" "${note_path}"
```

Or for PR-only items:

```bash
grep -nE "^## .*#${PR_NUMBER}( |$)" "${note_path}"
```

### If Section EXISTS → Update

1. Determine the section boundaries (from this H2 to the next H2 or `---`)
2. Update the `status::` field if the Linear state has changed:
   - Use `Edit` to replace `status:: <old>` with `status:: <new>`
3. Append a new timestamped entry at the end of the section (before the next H2 or `---`):
   ```
   - `HH:MM` <notes or generated description>
   ```
4. If the user provided notes, use those. Otherwise generate a brief note like "Picked up ticket" or "Checking PR status"

### If Section DOES NOT EXIST → Create

Build a new H2 section block:

```markdown
## <TICKET-ID> <title-slug>
ticket:: [<TICKET-ID>](<linear-url>)
pr:: [#<number>](<github-pr-url>)
branch:: `<headRefName>`
status:: <current-state-lowercase>
commented:: false

- `HH:MM` <notes or "Picked up ticket">
```

**Field rules:**
- `ticket::` — Always present for Linear tickets. Omit if PR-only with no linked ticket.
- `pr::` — Present if a PR exists. Omit if ticket-only (no PR yet). Format: `[#number](url)` or `[repo#number](url)` for non-primary repos.
- `branch::` — The PR's head branch name in backticks. Extract from `headRefName` when fetching PR details. Omit if no PR exists.
- `status::` — Lowercase Linear state: `in-progress`, `in-review`, `done`, `blocked`, `todo`, `backlog`, `triage`
- `commented::` — Always starts as `false`. Updated by `/work:eod`.

**Formatting:** Write each property on its own line with NO trailing backslash and NO blank lines between properties. Tolaria's linter converts a trailing `\` (markdown hard break) into a blank line, which breaks the consecutive inline-field block. Each `key:: value` line is parsed as a separate property regardless of soft line breaks — do not add `\` or blank `\` separator lines. If you find existing sections with trailing backslashes, clean them while you're there.

**Insertion point:** Find the `<!-- track-work:items -->` comment and insert the new section after the next blank line. If the comment doesn't exist, insert before the `---` that precedes `# Meetings`.

## Step 4: Report

Output a brief confirmation:

```
Tracked DXO-71 (in-progress) in today's note
  → fix(sdk-release): replace unreliable !failure()
  → PR: #23274
  → Added: "Picked up ticket, reviewing PR feedback"
```

## Item Section Format Reference

A fully populated item section:

```markdown
## DXO-71 fix(sdk-release): replace unreliable !failure()
ticket:: [DXO-71](https://linear.app/ditto/issue/DXO-71)
pr:: [#23274](https://github.com/getditto/ditto/pull/23274)
branch:: `ben/dxo-71/fix-sdk-release-if-conditions`
status:: in-progress
commented:: false

- `09:14` Picked up ticket, reviewing PR feedback
- `11:30` Kicked off test release
- `14:02` Test release passed, moving to review
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Today's note doesn't exist | Error: "Run `/work:start` first" |
| Ticket ID not found in Linear | Error with message; suggest checking the ID |
| PR has linked Linear ticket | Populate both `ticket::` and `pr::` fields |
| Ticket has no PR yet | Omit `pr::` line; add it on future updates if a PR appears |
| Multiple PRs for one ticket | Use the most recently updated PR |
| Item already tracked, status unchanged | Just append timestamped note |
| Item already tracked, status changed | Update `status::` field AND append note mentioning the transition |
| User provides just a number | Prepend `DXO-` (default team) |
| PR from non-getditto/ditto repo | Use `repo#number` format: `[build-infra#608](url)` |
| No notes provided | Generate contextual note: "Picked up ticket", "Checking status", "Continuing work" based on whether this is first touch or update |
