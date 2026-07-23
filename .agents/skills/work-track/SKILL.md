---
name: work-track
description: Track a Linear ticket or GitHub PR in today's daily note with fields and timestamped activity. Use when invoked as `$work-track` or when the user asks to track a work item.
---

# work-track

Add or update a Linear ticket or GitHub PR in today's daily note. Each item gets an H2 section with inline fields and timestamped activity.

On macOS, run every `linear ...` command outside the sandbox on the first
attempt so the CLI can access credentials stored in the system keychain. Use
scoped escalation with `prefix_rule: ["linear"]`. If a sandboxed command
reports `No keyring entry` or `No API key configured`, retry outside the
sandbox before asking the user to authenticate. Never print, log, or expose
`linear auth token` or an API key.

## Arguments

Accept:

- Linear ticket ID such as `DXO-71` or `DEVX-943`.
- GitHub PR URL or shorthand such as `getditto/ditto#23274`.
- Optional freeform notes.

If the user provides only a number, assume `DXO-<number>`.

## Workflow

1. Locate today's note:

   ```bash
   today_date=$(date +%Y-%m-%d)
   today_day=$(date +%A)
   today_year=$(date +%Y)
   note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"
   ```

   If missing, tell the user to run `$work-start` first.

2. Fetch item details:

   - For Linear tickets, use available Linear MCP tools or `linear issue view`. Extract identifier, title, state, and URL.
   - For GitHub PRs, run `gh pr view <target> --json number,title,state,url,repository,headRefName`.
   - Detect linked Linear tickets or PRs from descriptions/comments where possible.

3. Search for an existing section:

   ```bash
   grep -nE "^## .*${TICKET_ID}( |$)" "${note_path}"
   grep -nE "^## .*#${PR_NUMBER}( |$)" "${note_path}"
   ```

4. If a section exists:

   - Update `status::` if changed.
   - Append `- \`HH:MM\` <note>` before the next H2 or section boundary.
   - Include a PR link when tracking a PR.

5. If no section exists, insert a block:

   ```markdown
   ## <TICKET-ID> <title-slug>
   ticket:: [<TICKET-ID>](<linear-url>)
   pr:: [#<number>](<github-pr-url>)
   branch:: `<headRefName>`
   status:: <current-state-lowercase>
   commented:: false

   - `HH:MM` <notes or generated activity>
   ```

   Omit fields that do not apply, except `commented:: false` should be present for Linear-tracked work.

6. Formatting rules:

   - Keep each `key:: value` on its own line.
   - Do not add trailing backslashes.
   - Do not insert blank lines between inline fields.
   - Insert after `<!-- track-work:items -->` when present, otherwise before the `---` preceding `# Meetings`.

7. Report item, status, PR/branch if known, and the note that was appended.
