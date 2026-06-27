# Cursor Harness Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the shared agent harness to Cursor as a tracked plugin-backed harness target.

**Architecture:** Keep `.agents/harness/` as the canonical source. Generate a Cursor plugin source under `.agents/harness/adapters/cursor/` and keep `.cursor/` runtime state ignored. Cursor gets native plugin artifacts where supported: rules, skills, agents, commands, hooks, and MCP registration.

**Tech Stack:** Python generator in `scripts/agent-harnesses.py`, Bats tests, Cursor plugin structure, `cursor-agent` CLI smoke checks, shared Python safety guard, code-review-graph MCP.

---

## Current Facts

- Cursor plugin directories use `.cursor-plugin/plugin.json`.
- Cursor plugin content can include `rules/`, `skills/`, `agents/`, `commands/`, `hooks/`, `mcp.json`, `assets/`, and `scripts/`.
- Cursor supports Project/User/Team rules plus `AGENTS.md`; Cursor CLI also reads `.cursor/rules`, `AGENTS.md`, and `CLAUDE.md`.
- Local plugin testing can use a symlink under `~/.cursor/plugins/local/<plugin-name>`.
- Source references checked on 2026-06-27:
  - `https://cursor.com/docs/reference/plugins`
  - `https://cursor.com/docs/plugins`
  - `https://cursor.com/docs/rules`
  - `https://cursor.com/docs/cli/using`

## File Structure

- Modify: `scripts/agent-harnesses.py`
  - Add Cursor renderers for plugin manifest, rules, commands, skills, agents, hooks, and MCP.
- Modify: `tests/agent-harnesses.bats`
  - Add Cursor artifact and JSON validation tests.
- Modify: `docs/agent-harnesses.json`
  - Generated matrix output.
- Modify: `docs/agent-harnesses.md`
  - Generated matrix output.
- Create: `.agents/harness/adapters/cursor/.cursor-plugin/plugin.json`
  - Cursor plugin manifest.
- Create: `.agents/harness/adapters/cursor/rules/shared-harness.mdc`
  - Rule that loads shared instructions and compact-preservation requirements.
- Create: `.agents/harness/adapters/cursor/commands/**/*.md`
  - Command wrappers for the 22 shared prompts.
- Create: `.agents/harness/adapters/cursor/agents/*.md`
  - Agent wrappers for the six shared specialists.
- Create: `.agents/harness/adapters/cursor/skills/*/SKILL.md`
  - Shared skill wrappers that point to `~/.agents/skills`.
- Create: `.agents/harness/adapters/cursor/hooks/hooks.json`
  - Hook declarations that call the shared guard wrapper.
- Create: `.agents/harness/adapters/cursor/scripts/harness-guard.py`
  - Native wrapper around `scripts/agent-harnesses.py guard --harness cursor`.
- Create: `.agents/harness/adapters/cursor/mcp.json`
  - Cursor MCP registration for code-review-graph.

### Task 1: Add Failing Cursor Tests

**Files:**
- Modify: `tests/agent-harnesses.bats`

- [ ] **Step 1: Add generated artifact test**

```bash
@test "agent-harnesses: cursor plugin artifacts exist" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  [ -f "$HOME/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/rules/shared-harness.mdc" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/commands/git/commit.md" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/agents/triage-expert.md" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/hooks/hooks.json" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/mcp.json" ]
}
```

- [ ] **Step 2: Add manifest JSON validation**

```bash
@test "agent-harnesses: cursor plugin manifest parses" {
  run jq . "$HOME/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json"

  [ "$status" -eq 0 ]
}
```

- [ ] **Step 3: Confirm red state**

Run:

```bash
bats tests/agent-harnesses.bats
```

Expected: the new artifact test fails because Cursor plugin files do not exist.

### Task 2: Generate Plugin Manifest and Rule

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/cursor/.cursor-plugin/plugin.json`
- Create: `.agents/harness/adapters/cursor/rules/shared-harness.mdc`

- [ ] **Step 1: Add path constants**

```python
CURSOR_HARNESS = SHARED / "adapters" / "cursor"
CURSOR_PLUGIN = CURSOR_HARNESS / ".cursor-plugin"
CURSOR_RULES = CURSOR_HARNESS / "rules"
```

- [ ] **Step 2: Add plugin manifest renderer**

```python
def render_cursor_plugin_manifest() -> str:
    manifest = {
        "name": "shared-agent-harness",
        "version": "1.0.0",
        "description": "Shared agent harness adapter for Cursor.",
    }
    return json.dumps(manifest, indent=2, sort_keys=True) + "\n"
```

- [ ] **Step 3: Add shared rule renderer**

```python
def render_cursor_rule() -> str:
    return f"""---
description: Load the shared agent harness for every Cursor session.
alwaysApply: true
---

{MANAGED_HEADER}

Load repository instructions first, then follow `~/.agents/harness/instructions.md`.
Use shared skills from `~/.agents/skills` when a task matches a skill description.
Preserve modified files, current branch, pending tasks, test results, and harness parity gaps during compaction or handoff.
"""
```

- [ ] **Step 4: Register generated files**

In `render_all`, add:

```python
rendered[CURSOR_PLUGIN / "plugin.json"] = render_cursor_plugin_manifest()
rendered[CURSOR_RULES / "shared-harness.mdc"] = render_cursor_rule()
```

- [ ] **Step 5: Generate and inspect**

Run:

```bash
python3 scripts/agent-harnesses.py generate
jq . .agents/harness/adapters/cursor/.cursor-plugin/plugin.json
sed -n '1,80p' .agents/harness/adapters/cursor/rules/shared-harness.mdc
```

Expected: manifest parses and the rule points to `~/.agents/harness/instructions.md`.

### Task 3: Generate Commands, Agents, and Skills

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/cursor/commands/**/*.md`
- Create: `.agents/harness/adapters/cursor/agents/*.md`
- Create: `.agents/harness/adapters/cursor/skills/*/SKILL.md`

- [ ] **Step 1: Add command renderer**

```python
def render_cursor_command(command: dict[str, Any]) -> str:
    return f"""---
description: {json.dumps(command["description"])[1:-1]}
---

{MANAGED_HEADER}

Execute the shared `{command["id"]}` command prompt from:

`{command["shared"]}`

Pass user arguments through unchanged.
"""
```

- [ ] **Step 2: Add agent renderer**

```python
def render_cursor_agent(agent: dict[str, Any]) -> str:
    return f"""---
name: {agent["id"]}
description: {json.dumps(agent["description"])[1:-1]}
---

{MANAGED_HEADER}

Load the shared specialist definition from `{agent["shared"]}` before acting.
"""
```

- [ ] **Step 3: Add skill wrapper renderer**

```python
def render_cursor_skill(skill_name: str) -> str:
    return f"""---
name: {skill_name}
description: Load the shared skill from ~/.agents/skills/{skill_name}/SKILL.md.
---

{MANAGED_HEADER}

Load and follow the shared skill at `~/.agents/skills/{skill_name}/SKILL.md`.
"""
```

- [ ] **Step 4: Register generated files**

In the command, agent, and skill generation loops, add:

```python
rendered[CURSOR_HARNESS / "commands" / Path(command["id"] + ".md")] = render_cursor_command(command)
rendered[CURSOR_HARNESS / "agents" / f"{agent['id']}.md"] = render_cursor_agent(agent)
rendered[CURSOR_HARNESS / "skills" / skill_name / "SKILL.md"] = render_cursor_skill(skill_name)
```

- [ ] **Step 5: Generate and count**

Run:

```bash
python3 scripts/agent-harnesses.py generate
find .agents/harness/adapters/cursor/commands -name '*.md' | wc -l
find .agents/harness/adapters/cursor/agents -name '*.md' | wc -l
find .agents/harness/adapters/cursor/skills -name SKILL.md | wc -l
```

Expected: 22 commands, six agents, and the same skill count as `python3 scripts/agent-harnesses.py inventory --json`.

### Task 4: Add Safety Hooks and MCP

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/cursor/hooks/hooks.json`
- Create: `.agents/harness/adapters/cursor/scripts/harness-guard.py`
- Create: `.agents/harness/adapters/cursor/mcp.json`

- [ ] **Step 1: Add guard wrapper renderer**

```python
def render_cursor_guard() -> str:
    return """#!/usr/bin/env python3
import json
import subprocess
import sys

payload = json.load(sys.stdin)
tool = payload.get("tool", "")
command = payload.get("command", "")
path = payload.get("path", "")
content = payload.get("content", "")
result = subprocess.run(
    ["python3", "scripts/agent-harnesses.py", "guard", "--harness", "cursor", "--tool", tool, "--command", command, "--path", path, "--content", content],
    text=True,
    stdout=subprocess.PIPE,
    check=False,
)
print(result.stdout, end="")
raise SystemExit(result.returncode)
"""
```

- [ ] **Step 2: Add hook and MCP renderers**

```python
def render_cursor_hooks() -> str:
    hooks = {
        "version": 1,
        "hooks": {
            "tool_call": [
                {
                    "command": "python3 scripts/harness-guard.py",
                    "description": "Evaluate shell, write, and edit calls with the shared harness guard.",
                }
            ],
            "compaction": [
                {
                    "append": "Preserve modified files, current branch, pending tasks, test results, and harness parity gaps."
                }
            ],
        },
    }
    return json.dumps(hooks, indent=2, sort_keys=True) + "\n"


def render_cursor_mcp() -> str:
    mcp = {
        "mcpServers": {
            "code-review-graph": {
                "command": "mise",
                "args": [
                    "exec",
                    "pipx:code-review-graph",
                    "--",
                    "code-review-graph",
                    "serve",
                ],
            }
        }
    }
    return json.dumps(mcp, indent=2, sort_keys=True) + "\n"
```

- [ ] **Step 3: Register generated files**

```python
rendered[CURSOR_HARNESS / "hooks" / "hooks.json"] = render_cursor_hooks()
rendered[CURSOR_HARNESS / "mcp.json"] = render_cursor_mcp()
rendered[CURSOR_HARNESS / "scripts" / "harness-guard.py"] = render_cursor_guard()
```

- [ ] **Step 4: Smoke the shared guard**

Run:

```bash
python3 scripts/agent-harnesses.py guard --harness cursor --tool bash --command "rm -rf /"
```

Expected: exit code `2` and JSON decision `deny`.

### Task 5: Validate, Update Matrix, and Link Locally

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Modify: `docs/agent-harnesses.json`
- Modify: `docs/agent-harnesses.md`

- [ ] **Step 1: Mark implemented states**

After generation and validation work, update Cursor matrix states:

- `instructions.global`: `complete / adapter`
- `skills.shared`: `complete / native`
- `commands.active`: `complete / native`
- `agents.specialists`: `complete / native`
- `hooks.safety`: `partial / adapter` until Cursor confirms pre-tool blocking behavior
- `mcp.code_review_graph`: `partial / native` until Cursor inventory confirms MCP registration
- `sessions.compaction`: `partial / native` until resume/history behavior is verified

- [ ] **Step 2: Run deterministic checks**

```bash
python3 scripts/agent-harnesses.py generate --check
just harness-check
bats tests/agent-harnesses.bats
```

Expected: all pass.

- [ ] **Step 3: Optional local plugin link**

Run only after deterministic checks pass:

```bash
mkdir -p ~/.cursor/plugins/local
ln -sfn "$HOME/.agents/harness/adapters/cursor" "$HOME/.cursor/plugins/local/shared-agent-harness"
```

Expected: Cursor can discover the plugin from the local plugin directory without tracking `.cursor/` runtime state.
