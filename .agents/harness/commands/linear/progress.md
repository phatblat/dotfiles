---
description: Post a short progress update comment to a Linear ticket
model: sonnet
argument_hint: "<TICKET-ID>"
allowed-tools:
  - Bash(linear:*)
  - Bash(date:*)
  - Bash(grep:*)
  - Read
  - Edit
category: workflow
---

# Post Linear Progress Comment

Post a concise progress update comment to a Linear ticket. Summarizes what's been done, what's in flight, and what's next.

On macOS, run every `linear ...` command outside the sandbox on the first
attempt so the CLI can access credentials stored in the system keychain. Use
scoped escalation with `prefix_rule: ["linear"]`. If a sandboxed command
reports `No keyring entry` or `No API key configured`, retry outside the
sandbox before asking the user to authenticate. Never print, log, or expose
`linear auth token` or an API key.

## Arguments

`$ARGUMENTS` — a Linear ticket ID (e.g., `DEVX-927`, `FORGE-1101`).

If omitted, detect from the current git branch:

```bash
linear issue id 2>/dev/null
```

If that also fails, error: "No ticket ID provided and could not detect one from the current branch."

## Step 1: Fetch Ticket State

```bash
linear issue view <TICKET-ID> --no-pager
```

Extract:
- Current state
- Title
- Assignee (confirm it's @benchatelain — skip if unassigned or someone else)
- Linked PRs from Attachments section

## Step 2: Read Today's Activity Log

Find today's note:

```bash
today_date=$(date +%Y-%m-%d)
today_day=$(date +%A)
today_year=$(date +%Y)
note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"
```

Search the Work Items section for a block matching the ticket ID:

```bash
grep -n "<TICKET-ID>" "${note_path}"
```

If a matching H2 section exists, extract:
- `status::` field
- `pr::` field (if present)
- All timestamped log entries (`- \`HH:MM\` ...`)

If no section exists in today's note, use only the ticket's Linear state and PR status from Step 1.

## Step 3: Compose the Comment

Write a brief, direct progress comment. Format:

```markdown
**Progress update — YYYY-MM-DD**

Status: <current state>
PR: <link and state if applicable, e.g. "forge#887 — open, pending review">

<2-4 sentences summarizing: what was done today, current blockers if any, and immediate next step.>
```

**Tone:** Factual and concise. No filler phrases ("working on", "making progress"). Lead with the most recent concrete action. If there's a blocker, name it specifically.

**Example:**

```markdown
**Progress update — 2026-06-30**

Status: In Review
PR: build-infra#602 — approved, awaiting merge

Playbook refactor complete. Extracted reusable Ansible roles for mise, xcode, certificates, and GHA runner teardown. PR is approved; blocked on merge while verifying PAT scope for repo-level runner registration on getditto/ditto.
```

If today's activity log is empty (no log entries in the daily note), compose from Linear state + PR status alone. Keep it to 1-2 sentences.

## Step 4: Present for Confirmation

Show the draft comment and ask:

```
## Draft comment for <TICKET-ID>

> **Progress update — YYYY-MM-DD**
>
> Status: In Review
> PR: build-infra#602 — approved, awaiting merge
>
> Playbook refactor complete. ...

Post this comment?
```

Use `AskUserQuestion` with options:
- **Post** — post as-is
- **Edit** — user provides revised text, then post
- **Skip** — don't post

## Step 5: Post the Comment

Write the body to a temp file, then post:

```bash
cat > /tmp/linear-progress-<TICKET-ID>.md << 'EOF'
<comment body>
EOF

linear issue comment add <TICKET-ID> --body-file /tmp/linear-progress-<TICKET-ID>.md
```

## Step 6: Update Daily Note

If posted, update the Work Items section in today's note:
- Set `commented:: true` for this ticket
- Append a log entry: `- \`HH:MM\` Posted progress comment`

## Step 7: Report

```
✓ Posted progress comment to <TICKET-ID>
  <linear-url>
```

Or if skipped:
```
Skipped — no comment posted to <TICKET-ID>
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No ticket ID and no branch | Error: provide a ticket ID |
| Ticket not assigned to @benchatelain | Warn and ask before posting |
| No activity in today's note | Compose from Linear state + PR status only |
| Already commented today (`commented:: true`) | Warn: "Already commented today — post another?" and confirm |
| `linear issue comment add` fails | Report error; leave `commented::` unchanged |
