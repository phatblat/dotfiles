---
name: "session-save"
description: "Save the current agent session to the 2ndBrain vault with frontmatter, executive brief, and full transcript. Use when the user invokes $session-save or /skill:session-save."
---

# session-save

Use this skill when the user asks to save the session to 2ndBrain, or invokes `$session-save` or `/skill:session-save`.

Saves the current agent session as a note in `~/2ndBrain/agent-sessions/<year>/`. Supported harnesses: claude, omp, pi, codex. opencode, crush, and antigravity keep no JSONL transcript, so Step 2 errors out for them. Notes already in `~/2ndBrain/Codex-sessions/` stay where they are.

The note structure:
1. YAML frontmatter — date, hostname, harness, agent version, session name, cwd, git branch, token counts
2. Executive brief — 3–5 bullet summary of what was done, key decisions, and open items
3. `---` separator
4. Full session transcript — formatted as `**User**` / `**Assistant**` blocks with tool calls noted inline

## Step 1: Gather Environment Metadata

```bash
session_date=$(date +%Y-%m-%d)
session_time=$(date +%H:%M:%S)
session_year=$(date +%Y)
host=$(hostname -s)
cwd=$(pwd)
branch=$(git branch --show-current 2>/dev/null || echo "")
echo "date=${session_date} time=${session_time} host=${host} cwd=${cwd} year=${session_year} branch=${branch}"
```

## Step 2: Identify the Current Session File, Harness, and Version

Session transcripts live in different roots depending on which harness is running this skill. Do **not** pick the most recently modified `*.jsonl`: several agent sessions can be live at once, even in the same working directory, and a sibling session that is mid-turn has a newer mtime than the session running this skill. Identify the transcript that contains *this* invocation instead.

First write the invocation — the user message that triggered this skill, verbatim — to a marker file with the `write` tool, so no shell quoting can mangle it:

`${TMPDIR:-/tmp}/session-save-invocation.txt`

It is overwritten on every run, so it needs no cleanup. Then take the most recently modified transcript containing a user turn that matches the marker. There is deliberately no "newest file" fallback: a wrong transcript silently saves some other session. If nothing matches — usually because the harness has not flushed the current turn yet — report the error and stop. A full transcript cannot be rebuilt from context.

Record which root the winner came from as the `harness` (`claude`, `omp`, `pi`, or `codex`) so the note can be traced back to the agent that produced it, then resolve that harness's own CLI version.

```bash
roots=()
for d in "$HOME/.claude/projects" "$HOME/.omp/agent/sessions" "$HOME/.pi/agent/sessions" "$HOME/.codex/sessions"; do
  [ -d "$d" ] && roots+=("$d")
done
if [ "${#roots[@]}" -eq 0 ]; then
  echo "ERROR: No known session directory found" >&2
  exit 1
fi
session_file=$(MARKER="${TMPDIR:-/tmp}/session-save-invocation.txt" python3 - "${roots[@]}" << 'PYEOF'
import json, os, sys

with open(os.environ['MARKER'], encoding='utf-8') as f:
    marker = f.read().strip()
if not marker:
    sys.exit('ERROR: invocation marker file is empty')


def user_text(entry):
    """Joined text of a user turn, or '' for anything else."""
    if entry.get('type') == 'response_item':
        # Codex: {type: response_item, payload: {type: message, role, content}}
        payload = entry.get('payload')
        if not isinstance(payload, dict):
            return ''
        if payload.get('type') != 'message' or payload.get('role') != 'user':
            return ''
        blocks = payload.get('content')
        if not isinstance(blocks, list):
            return ''
        return '\n\n'.join(
            b.get('text', '') for b in blocks
            if isinstance(b, dict) and b.get('type') == 'input_text'
        )
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

## Step 3: Parse Session File

Run this Python script to extract all session data. It branches on `HARNESS` because each harness persists a different schema:
- claude: `type` is `"user"`/`"assistant"`, turn payload under `message`, `tool_use` blocks, `usage.output_tokens`.
- omp, pi: `type` is `"message"` with `message.role` (`toolResult` turns are skipped), `toolCall` blocks, `usage.output`; a `type: "session"` line carries the id, cwd and optional title, and a later `type: "title"` line overrides the title.
- codex: `type` is `"response_item"` with `payload.type == "message"`; `function_call`/`custom_tool_call` payloads are tool calls; `session_meta` carries the id, cwd and git branch. Codex transcripts have no token usage, so all counts stay 0.

```bash
SESSION_FILE="${session_file}" HARNESS="${harness}" BRANCH="${branch}" python3 << 'PYEOF'
import json, os, sys

session_file = os.environ['SESSION_FILE']
harness = os.environ['HARNESS']

SUMMARY_KEYS = ['command', 'path', 'file_path', 'query', 'skill', 'description']
# Codex injects these as user turns; they are context, not something the user typed.
CODEX_INJECTED = ('# AGENTS.md', '<environment_context>')

messages = []
total_output_tokens = 0
last_input_tokens = 0
session_id = None
ai_title = None
git_branch = None
session_cwd = None


def tool_line(name, args):
    detail = ''
    if isinstance(args, dict):
        detail = next((str(args[k])[:120] for k in SUMMARY_KEYS if k in args), '')
    return f'[→ {name}: {detail}]' if detail else f'[→ {name}]'


def block_parts(raw, text_types, call_type, args_key, skip_prefixes=()):
    """Text and tool-call summaries from a content value; results and thinking are omitted."""
    if isinstance(raw, str):
        raw = [{'type': text_types[0], 'text': raw}]
    parts = []
    if not isinstance(raw, list):
        return parts
    for block in raw:
        if not isinstance(block, dict):
            continue
        btype = block.get('type')
        if btype in text_types:
            text = (block.get('text') or '').strip()
            if text and not text.startswith(skip_prefixes):
                parts.append(text)
        elif btype == call_type:
            parts.append(tool_line(block.get('name', 'unknown'), block.get(args_key)))
    return parts


def add(role, parts):
    content = '\n'.join(parts).strip()
    if content:
        messages.append({'role': role, 'content': content})
        return True
    return False


with open(session_file, encoding='utf-8', errors='replace') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(entry, dict):
            continue
        etype = entry.get('type')

        if harness == 'claude':
            if not session_id:
                session_id = entry.get('sessionId')
            if not git_branch and 'gitBranch' in entry:
                git_branch = entry['gitBranch']
            if not session_cwd and 'cwd' in entry:
                session_cwd = entry['cwd']
            if etype == 'ai-title':
                ai_title = entry.get('aiTitle')
                continue
            if etype not in ('user', 'assistant'):
                continue
            msg = entry.get('message', {})
            if not isinstance(msg, dict):
                continue
            role = msg.get('role', etype)
            parts = block_parts(msg.get('content', ''), ('text',), 'tool_use', 'input')
            # Skip purely-meta user turns (no actual user text, just system context)
            if entry.get('isMeta', False) and role == 'user' and not any(not p.startswith('[') for p in parts):
                continue
            if not add(role, parts):
                continue
            usage = msg.get('usage') or {}
            out = usage.get('output_tokens', 0)
            inp_total = (usage.get('input_tokens', 0)
                         + usage.get('cache_creation_input_tokens', 0)
                         + usage.get('cache_read_input_tokens', 0))

        elif harness in ('omp', 'pi'):
            if etype == 'session':
                session_id = session_id or entry.get('id')
                session_cwd = session_cwd or entry.get('cwd')
                ai_title = entry.get('title') or ai_title
                continue
            if etype == 'title':
                ai_title = entry.get('title') or ai_title
                continue
            if etype != 'message':
                continue
            msg = entry.get('message')
            if not isinstance(msg, dict) or msg.get('role') not in ('user', 'assistant'):
                continue
            role = msg['role']
            if not add(role, block_parts(msg.get('content', ''), ('text',), 'toolCall', 'arguments')):
                continue
            usage = msg.get('usage') or {}
            out = usage.get('output', 0)
            inp_total = (usage.get('input', 0) + usage.get('cacheRead', 0) + usage.get('cacheWrite', 0))

        elif harness == 'codex':
            payload = entry.get('payload')
            if not isinstance(payload, dict):
                continue
            if etype == 'session_meta':
                session_id = session_id or payload.get('id')
                session_cwd = session_cwd or payload.get('cwd')
                git = payload.get('git')
                if not git_branch and isinstance(git, dict):
                    git_branch = git.get('branch')
                continue
            if etype != 'response_item':
                continue
            ptype = payload.get('type')
            if ptype == 'message' and payload.get('role') in ('user', 'assistant'):
                role = payload['role']
                skip = CODEX_INJECTED if role == 'user' else ()
                add(role, block_parts(payload.get('content'), ('input_text', 'output_text'), '', '', skip))
            elif ptype in ('function_call', 'custom_tool_call'):
                add('assistant', [tool_line(payload.get('name', 'unknown'), None)])
            continue

        else:
            print(json.dumps({'error': f'Unsupported harness: {harness}'}))
            sys.exit(1)

        if out:
            total_output_tokens += out
        if inp_total:
            last_input_tokens = inp_total

if not git_branch:
    git_branch = os.environ.get('BRANCH') or None

print(json.dumps({
    'harness': harness,
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
- Designed and wrote the /session-save command to ~/2ndBrain/agent-sessions/.
```

## Step 5: Determine Output Path

Use the `ai_title` from Step 3 if set; otherwise generate a 3–6 word title summarizing the conversation. Sanitize it for use as a filename: replace `/`, `:`, `|` with `-`; collapse spaces.

```
vault=~/2ndBrain
out_dir="${vault}/agent-sessions/${session_year}"
filename="${session_date} ${title}.md"
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
harness: <harness>
agent_version: <agent_version>
session: <title>
session_id: <session_id>
cwd: <session_cwd>
branch: <git_branch>
tokens:
  output: <total_output_tokens>
  context: <last_input_tokens>
  total: <total_tokens>
messages: <message_count>
tags:
  - agent-session
  - <harness>-session
---

## Executive Brief

<bullet points from Step 4>

---

## Session Transcript

<for each message in order:>

**User**

<content>

---

**Assistant**

<content>

---

<repeat for all messages>
```

Omit the `branch` or `agent_version` line if empty, and omit the whole `tokens` block when `total_tokens` is 0. Separate each message with `---`. Keep the full content of each message — do not truncate.

## Step 7: Report

Output a one-line confirmation, plus the token line only when `total_tokens` is greater than 0:

```
Session saved: ~/2ndBrain/agent-sessions/<year>/<filename>
Tokens: <last_input_tokens> context / <total_output_tokens> output / <total_tokens> total | Messages: <message_count>
```
