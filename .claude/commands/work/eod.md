---
description: End-of-day — draft and post daily comments for tracked tickets missing a comment
model: sonnet
allowed-tools:
  - Read
  - Edit
  - Bash(linear:*)
  - Bash(date:*)
  - Bash(grep:*)
  - Bash(cat:*)
  - Bash(mkdir:*)
  - AskUserQuestion
category: workflow
---

# End-of-Day Comments

Review today's tracked work items, draft Linear comments for tickets that haven't been commented on today, present for approval, and post. Takes no arguments.

## Step 1: Read Today's Note

```bash
today_date=$(date +%Y-%m-%d)
today_day=$(date +%A)
today_year=$(date +%Y)
note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"
```

Read the full note content.

## Step 2: Find Items Needing Comments

Parse the `# Work Items` section for all H2 item sections. For each item, extract:

- **Ticket ID** from the heading (e.g., `DXO-71`)
- **`ticket::` field** — the Linear URL (items without a `ticket::` field are PR-only; skip them)
- **`commented::` field** — if `true`, skip this item
- **`status::` field** — include in the comment for context
- **Activity log** — all timestamped bullet lines (`- \`HH:MM\` ...`)

Collect all items where `commented:: false` and a `ticket::` field exists.

If no items need comments, report "All tracked tickets already have today's comment." and exit.

## Step 3: Draft Comments

For each item needing a comment, draft a Linear comment from the activity log. Format:

```markdown
**Daily update — YYYY-MM-DD**

Status: <status>

- <activity bullet 1, without timestamp>
- <activity bullet 2, without timestamp>
- ...
```

Strip the backtick-wrapped timestamps from the bullets — they're note-internal, not useful in Linear.

If the activity log is empty (item was tracked but no notes added), draft a minimal comment:

```markdown
**Daily update — YYYY-MM-DD**

Status: <status>

Tracked today, no specific updates logged.
```

## Step 4: Present for Approval

Show ALL draft comments together, clearly labeled:

```
## Draft Linear Comments

### DXO-71 — fix(sdk-release): replace unreliable !failure()

> **Daily update — 2026-05-29**
>
> Status: in-progress
>
> - Picked up ticket, reviewing PR feedback
> - Kicked off test release
> - Test release passed, moving to review

### DEVX-943 — Decommission 6 older macOS CI runners

> **Daily update — 2026-05-29**
>
> Status: in-progress
>
> - Removed atl-mac03 from runner group
> - PR approved, merged
```

Then ask the user using `AskUserQuestion`:

- "Post these comments to Linear?" with options:
  - **Post all** — post every draft as-is
  - **Review individually** — step through each one for edit/skip/post
  - **Skip all** — don't post any; just mark as reviewed

### If "Review individually":

For each draft, ask:
- **Post** — post as-is
- **Edit** — user provides revised text, then post that
- **Skip** — don't post this one (leave `commented:: false`)

## Step 5: Post Comments

First invoke the `linear-cli:linear-cli` skill to load the correct CLI syntax.

On macOS, run every `linear ...` command outside the sandbox on the first
attempt so the CLI can access credentials stored in the system keychain. Use
scoped escalation with `prefix_rule: ["linear"]`. If a sandboxed command
reports `No keyring entry` or `No API key configured`, retry outside the
sandbox before asking the user to authenticate. Never print, log, or expose
`linear auth token` or an API key.

For each approved comment, write the body to a temp file then post using the CLI:

```bash
# Write comment body to a temp file (required for markdown content)
cat > /tmp/linear-comment-<TICKET-ID>.md << 'EOF'
<comment body>
EOF

# Post the comment
linear issue comment add <TICKET-ID> --body-file /tmp/linear-comment-<TICKET-ID>.md
```

After successful post, update the daily note:

```
Edit: commented:: false → commented:: true
```

Scope the edit to the specific item's section to avoid updating other items.

## Step 6: Report

```
## EOD Comments Posted

Posted: 2
  ✓ DXO-71 — fix(sdk-release): replace unreliable !failure()
  ✓ DEVX-943 — Decommission 6 older macOS CI runners

Skipped: 0

All tracked tickets have today's comment.
```

If any were skipped:

```
Skipped: 1
  ✗ DXO-88 — Title here (user chose to skip)

⚠ 1 in-progress ticket still needs a comment today.
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Today's note doesn't exist | Error: "No daily note found for today" |
| No items with `commented:: false` | Report "All done" and exit |
| PR-only items (no `ticket::` field) | Skip — can't post to Linear without a ticket |
| Linear API error on post | Report error for that ticket; continue with others |
| Empty activity log | Post minimal "Tracked today, no specific updates" comment |
| Item status is `done` | Still post the comment (important to close the loop) |
| User edits a draft | Use the edited text verbatim |
| Run twice same day | Second run finds all `commented:: true`; reports "All done" |
