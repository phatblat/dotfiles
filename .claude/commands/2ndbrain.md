---
description: Quick-save the last response as a note in the 2ndBrain Obsidian vault
allowed-tools:
  - Bash(date:*)
  - Bash(hostname:*)
  - Bash(pwd:*)
  - Bash(ls:*)
  - Bash(sed:*)
  - Bash(head:*)
  - Bash(echo:*)
  - Bash(mkdir:*)
  - Bash(python3:*)
  - Read
  - Write
category: workflow
---

# Save Last Response to 2ndBrain

Quick-captures the assistant's most recent reply (the one immediately before this
command was invoked) as a standalone note in `~/2ndBrain/quick-notes/<year>/`.
Unlike `/session-save`, this does not summarize or transcribe the whole session —
it captures exactly one response, verbatim, for fast reference later.

Optional `$ARGUMENTS` provide a title override and/or extra tags, e.g.
`/2ndbrain Redis eviction policy notes`. If omitted, generate a short 3-6 word
title that summarizes the captured response.

## Step 1: Gather Environment Metadata

```bash
note_date=$(date +%Y-%m-%d)
note_time=$(date +%H:%M:%S)
note_year=$(date +%Y)
host=$(hostname -s)
cwd=$(pwd)
branch=$(git branch --show-current 2>/dev/null || echo "")
echo "date=${note_date} time=${note_time} host=${host} cwd=${cwd} year=${note_year} branch=${branch}"
```

## Step 2: Find Current Session File

Session transcripts live in different roots depending on which harness is
running this command. Search all roots that exist and pick the most recently
modified `*.jsonl` — that is always the active session, since it is the file
being appended to right now.

```bash
roots=()
for d in "$HOME/.claude/projects" "$HOME/.omp/agent/sessions" "$HOME/.pi/agent/sessions" "$HOME/.codex/sessions" "$HOME/.Codex/projects"; do
  [ -d "$d" ] && roots+=("$d")
done
if [ "${#roots[@]}" -eq 0 ]; then
  echo "ERROR: No known session directory found" >&2
  exit 1
fi
session_file=$(find "${roots[@]}" -type f -iname "*.jsonl" -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
if [ -z "$session_file" ]; then
  echo "ERROR: No session file found under: ${roots[*]}" >&2
  exit 1
fi
echo "session_file=${session_file}"
```

## Step 3: Extract the Last Assistant Response

Run this Python script to pull the most recent assistant text turn. It handles
both known transcript schemas:
- Claude Code: one JSON object per turn, `type` is `"user"`/`"assistant"`,
  turn payload under `message`.
- Pi/OMP (and compatible): `type` is `"message"`, with `message.role` and
  `message.content` blocks; a `type: "session"` line carries the session id,
  a `type: "title"`/`"ai-title"` line carries an auto-generated title.

Tool-call/tool-result blocks are skipped; only `type: "text"` blocks count.

```bash
SESSION_FILE="${session_file}" python3 << 'PYEOF'
import json, os

session_file = os.environ['SESSION_FILE']

last_text = None
session_id = None
title_hint = None

with open(session_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        etype = entry.get('type')

        # Session id: Claude puts it on every line; pi/omp on a dedicated line.
        if not session_id:
            session_id = entry.get('sessionId') or (entry.get('id') if etype == 'session' else None)

        # Title hint: Claude's ai-title, or pi/omp's title/session line.
        if etype == 'ai-title':
            title_hint = entry.get('aiTitle')
            continue
        if etype in ('title', 'title_change') or (etype == 'session' and entry.get('title')):
            title_hint = entry.get('title') or title_hint

        # Message payload: Claude uses type in {user,assistant}; pi/omp uses type == 'message'.
        if etype not in ('user', 'assistant', 'message'):
            continue
        message = entry.get('message', {})
        if not isinstance(message, dict):
            continue
        role = message.get('role', etype)
        if role != 'assistant':
            continue

        raw_content = message.get('content', '')
        parts = []
        if isinstance(raw_content, list):
            for block in raw_content:
                if isinstance(block, dict) and block.get('type') == 'text':
                    text = block.get('text', '').strip()
                    if text:
                        parts.append(text)
        elif isinstance(raw_content, str) and raw_content.strip():
            parts.append(raw_content.strip())

        text = '\n\n'.join(parts).strip()
        if text:
            last_text = text

if not last_text:
    print(json.dumps({'error': 'No assistant text response found'}))
    raise SystemExit(1)

print(json.dumps({'session_id': session_id, 'title_hint': title_hint, 'text': last_text}, ensure_ascii=False))
PYEOF
```

Capture the JSON output. If it contains `"error"`, report the error and stop —
do not fabricate a response.

## Step 4: Determine Title and Output Path

- If `$ARGUMENTS` is non-empty, use it verbatim as the title.
- Else if `title_hint` from Step 3 is non-empty, use it as the title.
- Otherwise generate a short 3-6 word title summarizing the captured response text.
- Sanitize the title for use as a filename: replace `/`, `:`, `|` with `-`; collapse spaces.

```
vault=~/2ndBrain
out_dir="${vault}/quick-notes/${note_year}"
filename="${note_date} ${title}.md"
out_path="${out_dir}/${filename}"
```

Ensure the directory exists:
```bash
mkdir -p "${out_dir}"
```

## Step 5: Write the Note

Use the `Write` tool to create `${out_path}` with this structure:

```markdown
---
date: <YYYY-MM-DD>
time: <HH:MM:SS>
hostname: <host>
cwd: <cwd>
branch: <branch>
session_id: <session_id>
tags:
  - quick-save
---

<the captured response text, verbatim>
```

Omit the `branch` line if empty. Do not summarize, trim, or reformat the
captured text — write it exactly as extracted.

## Step 6: Report

Output a one-line confirmation:

```
Saved to 2ndBrain: ~/2ndBrain/quick-notes/<year>/<filename>
```
