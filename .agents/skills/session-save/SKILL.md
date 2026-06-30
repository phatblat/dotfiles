---
name: "session-save"
description: "Save current Codex session to 2ndBrain vault with frontmatter, executive brief, and full transcript"
---

# session-save

Use this skill when the user asks to run the migrated command `session-save` or invokes `$session-save`.

## Command Template

# Save Session to 2ndBrain

Saves the current Codex session as a note in `~/2ndBrain/Codex-sessions/<year>/`.

The note structure:
1. YAML frontmatter — date, hostname, session name, cwd, git branch, token counts
2. Executive brief — 3–5 bullet summary of what was done, key decisions, and open items
3. `---` separator
4. Full session transcript — formatted as `**User**: ...` / `**Codex**: ...` blocks with tool calls noted inline

## Step 1: Gather Environment Metadata

```bash
session_date=$(date +%Y-%m-%d)
session_time=$(date +%H:%M:%S)
session_year=$(date +%Y)
host=$(hostname -s)
cwd=$(pwd)
echo "date=${session_date} time=${session_time} host=${host} cwd=${cwd} year=${session_year}"
```

## Step 2: Find Current Session File

```bash
encoded_cwd=$(pwd | sed 's|/|-|g')
project_dir="$HOME/.Codex/projects/${encoded_cwd}"
session_file=$(ls -t "${project_dir}"/*.jsonl 2>/dev/null | head -1)
if [ -z "$session_file" ]; then
  echo "ERROR: No session file found in ${project_dir}" >&2
  exit 1
fi
echo "session_file=${session_file}"
```

## Step 3: Parse Session File

Run this Python script to extract all session data:

```bash
python3 << 'PYEOF'
import json, sys, os, subprocess, glob

cwd = subprocess.check_output(['pwd']).decode().strip()
encoded = cwd.replace('/', '-')
home = os.path.expanduser('~')
project_dir = f"{home}/.Codex/projects/{encoded}"
files = sorted(glob.glob(f"{project_dir}/*.jsonl"), key=os.path.getmtime, reverse=True)
session_file = files[0] if files else ''

if not session_file:
    print(json.dumps({'error': 'No session file found'}))
    sys.exit(1)

messages = []
total_output_tokens = 0
last_input_tokens = 0
session_id = None
ai_title = None
git_branch = None
session_cwd = None

with open(session_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        if not session_id:
            session_id = entry.get('sessionId')
        if not git_branch and 'gitBranch' in entry:
            git_branch = entry['gitBranch']
        if not session_cwd and 'cwd' in entry:
            session_cwd = entry['cwd']

        # Grab latest ai-title
        if entry.get('type') == 'ai-title':
            ai_title = entry.get('aiTitle')
            continue

        entry_type = entry.get('type')
        if entry_type not in ('user', 'assistant'):
            continue

        # Skip meta/system user turns (isMeta = true with no real content)
        is_meta = entry.get('isMeta', False)
        msg = entry.get('message', {})
        if not isinstance(msg, dict):
            continue

        role = msg.get('role', entry_type)
        raw_content = msg.get('content', '')

        # Parse content blocks into text
        parts = []
        if isinstance(raw_content, list):
            for block in raw_content:
                if not isinstance(block, dict):
                    continue
                btype = block.get('type')
                if btype == 'text':
                    text = block.get('text', '').strip()
                    if text:
                        parts.append(text)
                elif btype == 'tool_use':
                    name = block.get('name', 'unknown')
                    inp = block.get('input', {})
                    # Summarize key input fields
                    summary_keys = ['command', 'path', 'file_path', 'query', 'skill', 'description']
                    detail = next((str(inp[k])[:120] for k in summary_keys if k in inp), '')
                    if detail:
                        parts.append(f'[→ {name}: {detail}]')
                    else:
                        parts.append(f'[→ {name}]')
                elif btype == 'tool_result':
                    pass  # omit tool results from transcript
        elif isinstance(raw_content, str):
            if raw_content.strip():
                parts.append(raw_content.strip())

        content = '\n'.join(parts).strip()
        if not content:
            continue

        # Skip purely-meta user turns (no actual user text, just system context)
        if is_meta and role == 'user' and not any(p for p in parts if not p.startswith('[')):
            continue

        messages.append({'role': role, 'content': content})

        # Token accounting
        usage = msg.get('usage', {})
        out = usage.get('output_tokens', 0)
        inp_total = (usage.get('input_tokens', 0)
                     + usage.get('cache_creation_input_tokens', 0)
                     + usage.get('cache_read_input_tokens', 0))
        if out:
            total_output_tokens += out
        if inp_total:
            last_input_tokens = inp_total

print(json.dumps({
    'session_id': session_id,
    'ai_title': ai_title,
    'git_branch': git_branch,
    'session_cwd': session_cwd,
    'total_output_tokens': total_output_tokens,
    'last_input_tokens': last_input_tokens,
    'total_tokens': last_input_tokens + total_output_tokens,
    'message_count': len(messages),
    'messages': messages,
}, ensure_ascii=False))
PYEOF
```

Capture the JSON output from this script. If it contains `"error"`, report the error and stop.

## Step 4: Generate Executive Brief

Read the `messages` array from the parsed JSON. Based on the full conversation content, write a concise executive brief:

- **3–5 bullet points** covering: what was investigated/built, key decisions made, commands run or files changed, and any open items or next steps
- Tone: factual, past-tense, no filler ("we looked at", "the user asked" — just state what happened)
- Each bullet should be one sentence

Example format:
```
- Audited the obsidian-skills plugin and three work commands that reference ~/2ndBrain/daily-notes.
- Discovered the JSONL session format includes an ai-title field, session_id, cwd, gitBranch, and per-message usage stats.
- Designed and wrote the /session-save command to ~/2ndBrain/Codex-sessions/.
```

## Step 5: Determine Output Path

Use the `ai_title` from Step 3 (or "Untitled Session" if absent). Sanitize it for use as a filename: replace `/`, `:`, `|` with `-`; collapse spaces.

```
vault=~/2ndBrain
out_dir="${vault}/Codex-sessions/${session_year}"
filename="${session_date} ${ai_title}.md"
out_path="${out_dir}/${filename}"
```

Ensure the directory exists:
```bash
mkdir -p "${out_dir}"
```

## Step 6: Format and Write the Note

Use the `Write` tool to create `${out_path}` with this structure:

```markdown
---
date: <YYYY-MM-DD>
time: <HH:MM:SS>
hostname: <host>
session: <ai_title>
session_id: <session_id>
cwd: <session_cwd>
branch: <git_branch>
tokens:
  output: <total_output_tokens>
  context: <last_input_tokens>
  total: <total_tokens>
messages: <message_count>
tags:
  - Codex-session
---

## Executive Brief

<bullet points from Step 4>

---

## Session Transcript

<for each message in order:>

**User**

<content>

---

**Codex**

<content>

---

<repeat for all messages>
```

Separate each message with `---`. Keep the full content of each message — do not truncate.

## Step 7: Report

Output a one-line confirmation:

```
Session saved: ~/2ndBrain/Codex-sessions/<year>/<filename>
Tokens: <last_input_tokens> context / <total_output_tokens> output / <total_tokens> total | Messages: <message_count>
```
