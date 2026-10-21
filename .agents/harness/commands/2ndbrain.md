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
  - Bash(claude:*)
  - Bash(omp:*)
  - Bash(pi:*)
  - Bash(codex:*)
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

## Step 2: Identify the Current Session File, Harness, and Version

Session transcripts live in different roots depending on which harness is
running this command. Do **not** pick the most recently modified `*.jsonl`:
several agent sessions can be live at once, even in the same working
directory, and a sibling session that is mid-turn has a newer mtime than the
session running this command. Identify the transcript that contains *this*
invocation instead.

First write the invocation — the user message that triggered this command,
verbatim — to a marker file with the Write tool, so no shell quoting can
mangle it:

`${TMPDIR:-/tmp}/2ndbrain-invocation.txt`

It is overwritten on every run, so it needs no cleanup. Then take the most
recently modified transcript containing a user turn that matches the marker.
There is deliberately no "newest file" fallback: a wrong transcript silently
saves some other session's answer. If nothing matches — usually because the
harness has not flushed the current turn yet — skip to Step 4 and write the
note from the response already in context, which is equally authoritative.

Record which root the winner came from as the `harness` (`claude`, `omp`,
`pi`, or `codex`) so the note can be traced back to the agent that produced
it, then resolve that harness's own CLI version.

```bash
roots=()
for d in "$HOME/.claude/projects" "$HOME/.omp/agent/sessions" "$HOME/.pi/agent/sessions" "$HOME/.codex/sessions" "$HOME/.Codex/projects"; do
  [ -d "$d" ] && roots+=("$d")
done
if [ "${#roots[@]}" -eq 0 ]; then
  echo "ERROR: No known session directory found" >&2
  exit 1
fi
session_file=$(MARKER="${TMPDIR:-/tmp}/2ndbrain-invocation.txt" python3 - "${roots[@]}" << 'PYEOF'
import json, os, sys

with open(os.environ['MARKER'], encoding='utf-8') as f:
    marker = f.read().strip()
if not marker:
    sys.exit('ERROR: invocation marker file is empty')


def user_text(entry):
    """Joined text of a user turn, or '' for anything else."""
    if entry.get('type') not in ('user', 'message'):
        return ''
    message = entry.get('message')
    if not isinstance(message, dict):
        return ''
    if message.get('role', entry.get('type')) != 'user':
        return ''
    raw = message.get('content', '')
    if isinstance(raw, str):
        return raw
    if not isinstance(raw, list):
        return ''
    return '\n\n'.join(
        b.get('text', '') for b in raw
        if isinstance(b, dict) and b.get('type') == 'text'
    )


candidates = []
for root in sys.argv[1:]:
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            if not name.lower().endswith('.jsonl'):
                continue
            path = os.path.join(dirpath, name)
            try:
                candidates.append((os.stat(path).st_mtime, path))
            except OSError:
                continue

# Newest first, so a repeated invocation resolves to the current session.
for _mtime, path in sorted(candidates, reverse=True):
    try:
        with open(path, encoding='utf-8', errors='replace') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if marker in user_text(entry):
                    print(path)
                    raise SystemExit(0)
    except OSError:
        continue
PYEOF
)
if [ -z "$session_file" ]; then
  echo "ERROR: No transcript under ${roots[*]} contains the invocation" >&2
  exit 1
fi
case "$session_file" in
  "$HOME/.claude/projects/"*) harness="claude" ;;
  "$HOME/.omp/agent/sessions/"*) harness="omp" ;;
  "$HOME/.pi/agent/sessions/"*) harness="pi" ;;
  "$HOME/.codex/sessions/"*) harness="codex" ;;
  "$HOME/.Codex/projects/"*) harness="codex" ;;
  *) harness="unknown" ;;
esac
case "$harness" in
  claude) agent_version=$(claude --version 2>/dev/null | head -1) ;;
  omp)    agent_version=$(omp --version 2>/dev/null | head -1) ;;
  pi)     agent_version=$(pi --version 2>/dev/null | head -1) ;;
  codex)  agent_version=$(codex --version 2>/dev/null | head -1) ;;
  *)      agent_version="" ;;
esac
echo "session_file=${session_file} harness=${harness} agent_version=${agent_version}"
```

## Step 3: Extract the Captured Response

The captured response is the last assistant text turn **before the
invocation**, not the last one in the file. This command runs mid-turn: by the
time the script executes the agent has usually already emitted narration for
the current turn, so taking the last assistant turn overall captures that
narration instead of the answer the user asked to save. Locate the
invocation with the same marker file Step 2 used, then take the last
assistant text preceding it.

Run this Python script. It handles both known transcript schemas:
- Claude Code: one JSON object per turn, `type` is `"user"`/`"assistant"`,
  turn payload under `message`.
- Pi/OMP (and compatible): `type` is `"message"`, with `message.role` and
  `message.content` blocks; a `type: "session"` line carries the session id,
  a `type: "title"`/`"ai-title"` line carries an auto-generated title.

Tool-call/tool-result blocks are skipped; only `type: "text"` blocks count.
Matching the marker rather than "the last user turn" also ignores
harness-injected context (`<system-reminder>`, `<system-directive>`), which
is delivered in a user turn but is not one.

```bash
SESSION_FILE="${session_file}" MARKER="${TMPDIR:-/tmp}/2ndbrain-invocation.txt" python3 << 'PYEOF'
import json, os

session_file = os.environ['SESSION_FILE']
with open(os.environ['MARKER'], encoding='utf-8') as f:
    marker = f.read().strip()

turns = []  # ordered (role, text) for text-bearing turns only
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
        if role not in ('user', 'assistant'):
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
            turns.append((role, text))

# The invocation is the last user turn matching the marker Step 2 resolved.
invocation = None
for i, (role, text) in enumerate(turns):
    if role == 'user' and marker in text:
        invocation = i

if invocation is None:
    print(json.dumps({'error': 'Invocation not found in the resolved transcript'}))
    raise SystemExit(1)

# The captured response is the last assistant turn before the invocation.
captured = None
for role, text in turns[:invocation]:
    if role == 'assistant':
        captured = text

if not captured:
    print(json.dumps({'error': 'No assistant response found before the invocation'}))
    raise SystemExit(1)

print(json.dumps({'session_id': session_id, 'title_hint': title_hint, 'text': captured}, ensure_ascii=False))
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
harness: <harness>
agent_version: <agent_version>
session_id: <session_id>
tags:
  - quick-save
---

<the captured response text, verbatim>
```

Omit the `branch` or `agent_version` line if empty. Do not summarize, trim, or
reformat the captured text — write it exactly as extracted.

## Step 6: Report

Output a one-line confirmation:

```
Saved to 2ndBrain: ~/2ndBrain/quick-notes/<year>/<filename>
```
