# Antigravity Harness Port Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the shared agent harness to Google Antigravity CLI (`agy`) as the long-term Google harness target instead of Gemini CLI.

**Architecture:** Keep `.agents/harness/` as the canonical source. Generate a tracked Antigravity plugin source under `.agents/harness/adapters/antigravity/`, then validate/install it through `agy plugin validate` and `agy plugin install`. Do not track `.gemini/antigravity-cli/` runtime state beyond documented settings behavior; credentials, conversations, cache, logs, and trust state remain ignored.

**Tech Stack:** Python generator in `scripts/agent-harnesses.py`, Bats tests, Antigravity CLI `agy`, Antigravity plugin commands/hooks/skills/agents, MCP bridge scripts, shared Python safety guard.

---

## Current Facts

- Installed CLI: `agy 1.0.2`.
- Relevant local help:
  - `agy --help` exposes `--sandbox`, `--add-dir`, `--dangerously-skip-permissions`, and `plugin`.
  - `agy plugin --help` exposes `list`, `import`, `install`, `uninstall`, `enable`, `disable`, `validate`, and `link`.
  - `agy plugin import [source]` supports importing plugins from `gemini` or `claude`.
- Runtime settings are currently stored at `.gemini/antigravity-cli/settings.json`.

## File Structure

- Modify: `scripts/agent-harnesses.py`
  - Add Antigravity renderers for plugin manifest, commands, skills, agents, hooks, and MCP.
- Modify: `tests/agent-harnesses.bats`
  - Add artifact and `agy plugin validate` smoke coverage.
- Modify: `docs/agent-harnesses.json`
  - Generated matrix output.
- Modify: `docs/agent-harnesses.md`
  - Generated matrix output.
- Create: `.agents/harness/adapters/antigravity/plugin.json`
  - Antigravity plugin manifest.
- Create: `.agents/harness/adapters/antigravity/commands/**/*.md`
  - Command wrappers for the 22 shared prompts.
- Create: `.agents/harness/adapters/antigravity/agents/*.md`
  - Agent wrappers for six shared specialists.
- Create: `.agents/harness/adapters/antigravity/skills/*/SKILL.md`
  - Shared skill adapters or links.
- Create: `.agents/harness/adapters/antigravity/hooks/hooks.json`
  - Hook declarations that call shared guard wrappers.
- Create: `.agents/harness/adapters/antigravity/scripts/harness-guard.py`
  - Native wrapper around `scripts/agent-harnesses.py guard --harness antigravity`.
- Create: `.agents/harness/adapters/antigravity/mcp.json`
  - MCP registration for code-review-graph and shared harness tools.

### Task 1: Add Failing Antigravity Tests

**Files:**
- Modify: `tests/agent-harnesses.bats`

- [ ] **Step 1: Add generated artifact test**

```bash
@test "agent-harnesses: antigravity plugin artifacts exist" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  [ -f "$HOME/.agents/harness/adapters/antigravity/plugin.json" ]
  [ -f "$HOME/.agents/harness/adapters/antigravity/commands/git/commit.md" ]
  [ -f "$HOME/.agents/harness/adapters/antigravity/agents/triage-expert.md" ]
  [ -f "$HOME/.agents/harness/adapters/antigravity/hooks/hooks.json" ]
  [ -f "$HOME/.agents/harness/adapters/antigravity/mcp.json" ]
}
```

- [ ] **Step 2: Add optional validation smoke**

```bash
@test "agent-harnesses: antigravity plugin validates when agy is installed" {
  command -v agy >/dev/null 2>&1 || skip "agy not installed"

  run agy plugin validate "$HOME/.agents/harness/adapters/antigravity"

  [ "$status" -eq 0 ]
}
```

- [ ] **Step 3: Confirm red state**

Run:

```bash
bats tests/agent-harnesses.bats
```

Expected: the new artifact test fails because the plugin files do not exist.

### Task 2: Generate Plugin Manifest and Command Wrappers

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/antigravity/plugin.json`
- Create: `.agents/harness/adapters/antigravity/commands/**/*.md`

- [ ] **Step 1: Add path constants**

```python
ANTIGRAVITY_HARNESS = SHARED / "adapters" / "antigravity"
ANTIGRAVITY_COMMANDS = ANTIGRAVITY_HARNESS / "commands"
```

- [ ] **Step 2: Add manifest renderer**

```python
def render_antigravity_plugin_manifest() -> str:
    manifest = {
        "name": "shared-agent-harness",
        "version": "1.0.0",
        "description": "Shared agent harness adapter for Antigravity.",
    }
    return json.dumps(manifest, indent=2, sort_keys=True) + "\n"
```

- [ ] **Step 3: Add command renderer**

```python
def render_antigravity_command(command: dict[str, Any]) -> str:
    return f"""{MANAGED_HEADER}

Execute the shared `{command["id"]}` command prompt from:

`{command["shared"]}`

Pass user arguments through unchanged.
"""
```

- [ ] **Step 4: Register generated files**

In `render_all`, add:

```python
rendered[ANTIGRAVITY_HARNESS / "plugin.json"] = render_antigravity_plugin_manifest()
rendered[ANTIGRAVITY_COMMANDS / Path(command["id"] + ".md")] = render_antigravity_command(command)
```

- [ ] **Step 5: Generate and inspect**

Run:

```bash
python3 scripts/agent-harnesses.py generate
jq . .agents/harness/adapters/antigravity/plugin.json
sed -n '1,80p' .agents/harness/adapters/antigravity/commands/git/commit.md
```

Expected: manifest parses and command points to `~/.agents/harness/commands/git/commit.md`.

### Task 3: Generate Agents and Skills

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/antigravity/agents/*.md`
- Create: `.agents/harness/adapters/antigravity/skills/*/SKILL.md`

- [ ] **Step 1: Add agent renderer**

```python
def render_antigravity_agent(agent: dict[str, Any]) -> str:
    return f"""---
name: {agent["id"]}
description: {json.dumps(agent["description"])[1:-1]}
---

{MANAGED_HEADER}

Load the shared specialist definition from `{agent["shared"]}`.
"""
```

- [ ] **Step 2: Generate agent files**

In the agent loop:

```python
rendered[ANTIGRAVITY_HARNESS / "agents" / f"{agent['id']}.md"] = render_antigravity_agent(agent)
```

- [ ] **Step 3: Generate skill wrappers**

Add a `render_antigravity_skill(skill_name: str)` helper that emits:

```markdown
---
name: <skill-name>
description: Load the shared skill from ~/.agents/skills/<skill-name>/SKILL.md.
---

<!-- Generated by scripts/agent-harnesses.py; do not edit directly. -->

Load and follow the shared skill at `~/.agents/skills/<skill-name>/SKILL.md`.
```

- [ ] **Step 4: Generate and count**

Run:

```bash
python3 scripts/agent-harnesses.py generate
find .agents/harness/adapters/antigravity/agents -type f | wc -l
find .agents/harness/adapters/antigravity/skills -name SKILL.md | wc -l
```

Expected: six agents and the same skill count as `python3 scripts/agent-harnesses.py inventory --json`.

### Task 4: Add Safety Hooks and MCP

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Create: `.agents/harness/adapters/antigravity/hooks/hooks.json`
- Create: `.agents/harness/adapters/antigravity/scripts/harness-guard.py`
- Create: `.agents/harness/adapters/antigravity/mcp.json`

- [ ] **Step 1: Add guard wrapper renderer**

```python
def render_antigravity_guard() -> str:
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
    ["python3", "scripts/agent-harnesses.py", "guard", "--harness", "antigravity", "--tool", tool, "--command", command, "--path", path, "--content", content],
    text=True,
    stdout=subprocess.PIPE,
    check=False,
)
print(result.stdout, end="")
raise SystemExit(result.returncode)
"""
```

- [ ] **Step 2: Add hook and MCP renderers**

Add concrete renderers:

```python
def render_antigravity_hooks() -> str:
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


def render_antigravity_mcp() -> str:
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

Register both files in `render_all`:

```python
rendered[ANTIGRAVITY_HARNESS / "hooks" / "hooks.json"] = render_antigravity_hooks()
rendered[ANTIGRAVITY_HARNESS / "mcp.json"] = render_antigravity_mcp()
rendered[ANTIGRAVITY_HARNESS / "scripts" / "harness-guard.py"] = render_antigravity_guard()
```

- [ ] **Step 3: Validate generated JSON**

Run:

```bash
python3 scripts/agent-harnesses.py generate
jq . .agents/harness/adapters/antigravity/hooks/hooks.json
jq . .agents/harness/adapters/antigravity/mcp.json
```

Expected: both files parse and reference `code-review-graph` plus `scripts/harness-guard.py`.

- [ ] **Step 4: Smoke the shared guard**

Run:

```bash
python3 scripts/agent-harnesses.py guard --harness antigravity --tool bash --command "rm -rf /"
```

Expected: exit code `2` and JSON decision `deny`.

### Task 5: Validate, Update Matrix, and Install Locally

**Files:**
- Modify: `scripts/agent-harnesses.py`
- Modify: `docs/agent-harnesses.json`
- Modify: `docs/agent-harnesses.md`

- [ ] **Step 1: Mark implemented states**

After generation and validation work, update Antigravity matrix states:

- `instructions.global`: `complete / adapter`
- `skills.shared`: `partial / adapter` until native shared skill loading is verified
- `commands.active`: `complete / adapter`
- `agents.specialists`: `partial / emulated` until isolated specialist sessions are verified
- `hooks.safety`: `partial / adapter` until native pre-tool blocking is verified
- `mcp.code_review_graph`: `partial / adapter` until `agy` inventory confirms registration

- [ ] **Step 2: Validate plugin**

Run:

```bash
agy plugin validate .agents/harness/adapters/antigravity
```

Expected: exit code `0`.

- [ ] **Step 3: Optional local install**

Run only after validation:

```bash
agy plugin install .agents/harness/adapters/antigravity
agy plugin list
```

Expected: plugin appears in list and can be enabled.

- [ ] **Step 4: Run full checks**

```bash
python3 scripts/agent-harnesses.py generate --check
just harness-check
bats tests/agent-harnesses.bats
```

Expected: all pass.
