---
name: work-start
description: Morning startup workflow for daily notes, yesterday summary, agenda, status comments, meeting sections, and daily branch setup. Use when invoked as `$work-start` or when the user asks to start the work day.
---

# work-start

Create or refresh today's daily note, populate yesterday summary and agenda, post daily status comments when appropriate, create meeting sections, and run `$pr-daily`.

On macOS, run every `linear ...` command outside the sandbox on the first
attempt so the CLI can access credentials stored in the system keychain. Use
scoped escalation with `prefix_rule: ["linear"]`. If a sandboxed command
reports `No keyring entry` or `No API key configured`, retry outside the
sandbox before asking the user to authenticate. Never print, log, or expose
`linear auth token` or an API key.

## Workflow

1. Determine paths:

   ```bash
   today_date=$(date +%Y-%m-%d)
   today_day=$(date +%A)
   today_year=$(date +%Y)
   today_file="${today_date} ${today_day}"
   vault="$HOME/2ndBrain"
   notes_dir="${vault}/daily-notes/${today_year}"
   ```

2. Create today's note if missing from `${vault}/templates/daily-note.md`. Replace Obsidian date placeholders and fix the yesterday link to the most recent earlier daily note.

3. Update startup checks:

   - Query macOS GitHub Actions runner status with `gh api orgs/getditto/actions/runner-groups/8/runners`.
   - Leave Slack `#ci` unchecked unless a Slack integration is available.

4. Build the `## Yesterday` section from:

   - Previous daily note.
   - Active Linear tickets from DEVX and DXO.
   - GitHub PRs authored or updated by the user since the previous work day.
   - GitHub PRs reviewed by the user since the previous work day.

   Preserve the auto-population comment for reruns.

5. Build today's agenda:

   - Calendar events from available work calendar MCP tools, if configured.
   - DEVX/DXO tickets in `triage`, `backlog`, or `unstarted` state for the active cycle.
   - In-progress tickets that need daily comments.

   If calendar tools are unavailable, report that and continue with Linear/GitHub sections.

6. Post daily Linear status comments for in-progress tickets that do not already have today's comment by the user. Use `linear-cli:linear-cli` before Linear CLI commands.

7. Add or update Work Items sections in today's note using the same format as `$work-track`; set `commented:: true` for tickets that received comments.

8. Populate empty meeting sections under `# Meetings` with one H2 per meeting.

9. Run `$pr-daily` to set up the daily branch and draft PR.

10. Report daily note path, previous note, meetings, tickets needing comment, tickets to pick up, branch, and PR.

## Edge cases

- Running twice in one day should be idempotent.
- Monday should use the most recent previous note, normally Friday.
- Missing Linear, GitHub, or calendar auth should be reported without discarding other completed sections.
- If today's note already has a populated Yesterday section, do not overwrite it; refresh agenda and meetings only.
