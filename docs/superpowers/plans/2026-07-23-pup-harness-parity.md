# Pup Harness Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manage Pup 1.6.6 with mise, enable the complete Pup plugin in Claude and Codex, and expose deterministic configured state plus live plugin drift for both harnesses.

**Architecture:** mise owns the executable before Homebrew is removed. A focused `scripts/agent_plugins.py` module normalizes tracked Claude JSON and Codex TOML independently from live CLI output; `scripts/agent-harnesses.py` consumes configured state for deterministic generated docs and live state only for `audit`. Claude and Codex retain their native plugin managers and caches.

**Tech Stack:** Python 3 standard library, Bats, JSON, TOML, mise, Homebrew, Claude Code CLI, Codex CLI, Just

## Global Constraints

- Pin the Pup executable and Codex marketplace to exactly `1.6.6` / `v1.6.6`.
- Do not remove Homebrew Pup until the mise-managed binary reports `pup 1.6.6`.
- Preserve Pup configuration, OAuth sessions, macOS Keychain items, and the existing Claude Pup installation.
- Re-enable Claude Pup without reinstalling or upgrading its observed `0.25.0` plugin.
- Preserve the nine shared Pup skills in both harnesses: `dd-apm`, `dd-code-generation`, `dd-debugger`, `dd-docs`, `dd-file-issue`, `dd-logs`, `dd-monitors`, `dd-pup`, and `dd-symdb`.
- Install the complete Codex plugin from marketplace tag `v1.6.6`, including its additional `dd-triage-flaky-test` and `dd-unblock-pr` skills; its native manifest version is `0.62.0`.
- Keep `datadog@openai-curated` uninstalled and Codex `features.apps = false`.
- Generated docs must depend only on tracked configuration; live CLI failures appear as unavailable audit state.
- Version differences are visible but are not parity errors.
- Limit plugin tracking to Claude and Codex in this iteration.
- Use the repository's `git-commit` skill for every commit and include `Co-Authored-By: Codex <noreply@openai.com>` exactly once.
- Push each completed logical commit to `phatblat/thursday`.

---

### Task 1: Migrate Pup from Homebrew to mise

**Files:**

- Modify: `.config/mise/config.toml`
- Modify: `Brewfile`
- Modify: `.config/homebrew/trust.json`

**Interfaces:**

- Consumes: the upstream `DataDog/pup` GitHub release tagged `v1.6.6`
- Produces: a mise-managed `pup` executable reporting `pup 1.6.6`

- [ ] **Step 1: Confirm the migration preconditions**

Run:

```bash
git status --short
brew list --versions datadog-labs/pack/pup
mise ls-remote github:DataDog/pup | rg '^1\.6\.6$'
```

Expected:

- Git status is clean.
- Homebrew reports `pup 1.6.6`.
- mise reports `1.6.6` as an available release.

- [ ] **Step 2: Declare Pup in mise**

Add this entry in alphabetic order among the `[tools]` keys in
`.config/mise/config.toml`:

```toml
"github:DataDog/pup" = "1.6.6"
```

Run:

```bash
just format-mise
mise fmt --check
```

Expected: both commands exit successfully.

- [ ] **Step 3: Install and verify Pup through mise**

Run:

```bash
mise install github:DataDog/pup@1.6.6
mise which pup
mise exec github:DataDog/pup@1.6.6 -- pup --version
```

Expected:

- `mise which pup` resolves under `~/.local/share/mise/installs/`.
- Direct mise execution prints `pup 1.6.6`.

If installation or verification fails, remove only the new mise declaration,
run `just format-mise`, and stop. Leave Homebrew and Pup user data unchanged.

- [ ] **Step 4: Remove the verified Homebrew installation**

Only after Step 3 succeeds, run:

```bash
brew uninstall datadog-labs/pack/pup
brew untap datadog-labs/pack
```

Expected: the formula and now-unused tap are removed. Do not delete
`~/.config/pup` or any Keychain entries.

- [ ] **Step 5: Remove obsolete Homebrew declarations**

Delete these exact lines from `Brewfile`:

```ruby
tap "datadog-labs/pack"
brew "datadog-labs/pack/pup"
```

Delete this exact entry from `.config/homebrew/trust.json`:

```json
"datadog-labs/pack/pup",
```

Run:

```bash
just format-json
```

Expected: the JSON remains valid and sorted.

- [ ] **Step 6: Verify package-manager ownership**

Run:

```bash
zsh -lic 'command -v pup && pup --version'
mise which pup
if brew list --formula pup >/dev/null 2>&1; then exit 1; fi
if brew tap | rg -q '^datadog-labs/pack$'; then exit 1; fi
if rg -n 'datadog-labs/pack|brew "[^"]*pup"' Brewfile .config/homebrew/trust.json; then exit 1; fi
just package-audit
```

Expected:

- The login shell resolves mise Pup and prints `pup 1.6.6`.
- Homebrew no longer lists the formula or tap.
- No Homebrew Pup declarations remain.
- The package audit does not report Pup as duplicated.

- [ ] **Step 7: Roll back a failed post-removal verification**

Skip this step when Step 6 passes. Otherwise restore:

```ruby
tap "datadog-labs/pack"
brew "datadog-labs/pack/pup"
```

```json
"datadog-labs/pack/pup",
```

Then run:

```bash
brew tap datadog-labs/pack
brew install datadog-labs/pack/pup
mise uninstall github:DataDog/pup@1.6.6
just format-mise
just format-json
zsh -lic 'command -v pup && pup --version'
```

Expected: Homebrew Pup 1.6.6 works again. Stop without committing.

- [ ] **Step 8: Verify, commit, and push the migration**

Run:

```bash
just format
just lint
git diff --check
git add .config/mise/config.toml Brewfile .config/homebrew/trust.json
git diff --cached --check
```

Invoke `$git-commit` with expected subject:

```text
chore(mise): Manage Pup with mise
```

Then run:

```bash
git push
git status --short --branch
```

Expected: commit and push succeed; the branch is clean and synchronized.

---

### Task 2: Normalize Tracked and Live Plugin State

**Files:**

- Create: `scripts/agent_plugins.py`
- Create: `tests/test_agent_plugins.py`
- Modify: `tests/agent-harnesses.bats`

**Interfaces:**

- Consumes: `.claude/settings.json`, `.codex/config.toml`, Claude list JSON, and Codex list JSON
- Produces: `configured_plugins(root: Path) -> dict[str, list[dict[str, Any]]]`
- Produces: `normalize_live_plugins(harness: str, payload: Any) -> list[dict[str, Any]]`
- Produces: `audit_plugins(configured: dict[str, list[dict[str, Any]]]) -> dict[str, Any]`

- [ ] **Step 1: Add failing unit tests for tracked configuration**

Create `tests/test_agent_plugins.py` with temporary Claude and Codex configs:

```python
#!/usr/bin/env python3
"""Tests for Claude/Codex plugin inventory normalization."""

from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from agent_plugins import (  # noqa: E402
    configured_plugins,
    normalize_live_plugins,
)


class ConfiguredPluginTests(unittest.TestCase):
    def test_normalizes_tracked_claude_and_codex_plugins(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".claude").mkdir()
            (root / ".codex").mkdir()
            (root / ".claude" / "settings.json").write_text(
                json.dumps(
                    {
                        "enabledPlugins": {
                            "pup@datadog-pup": True,
                            "disabled@example": False,
                        },
                        "extraKnownMarketplaces": {
                            "datadog-pup": {
                                "source": {
                                    "source": "github",
                                    "repo": "DataDog/pup",
                                }
                            }
                        },
                    }
                )
            )
            (root / ".codex" / "config.toml").write_text(
                """
[marketplaces.datadog-pup]
source_type = "git"
source = "https://github.com/DataDog/pup.git"

[plugins."pup@datadog-pup"]
enabled = true

[plugins."disabled@example"]
enabled = false
""".lstrip()
            )

            result = configured_plugins(root)

        self.assertEqual(
            result["claude"],
            [
                {
                    "id": "disabled@example",
                    "enabled": False,
                    "marketplace": "example",
                    "marketplace_source": None,
                },
                {
                    "id": "pup@datadog-pup",
                    "enabled": True,
                    "marketplace": "datadog-pup",
                    "marketplace_source": "github:DataDog/pup",
                },
            ],
        )
        self.assertEqual(result["codex"][1]["id"], "pup@datadog-pup")
        self.assertEqual(
            result["codex"][1]["marketplace_source"],
            "https://github.com/DataDog/pup.git",
        )
```

- [ ] **Step 2: Add failing unit tests for live schemas**

Append to `tests/test_agent_plugins.py`:

```python
class LivePluginTests(unittest.TestCase):
    def test_normalizes_claude_list_schema(self) -> None:
        result = normalize_live_plugins(
            "claude",
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "0.25.0",
                    "scope": "user",
                    "enabled": False,
                }
            ],
        )
        self.assertEqual(
            result,
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "0.25.0",
                    "installed": True,
                    "enabled": False,
                    "scope": "user",
                }
            ],
        )

    def test_normalizes_codex_list_schema(self) -> None:
        result = normalize_live_plugins(
            "codex",
            {
                "installed": [
                    {
                        "pluginId": "pup@datadog-pup",
                        "version": "1.6.6",
                        "installed": True,
                        "enabled": True,
                    }
                ]
            },
        )
        self.assertEqual(
            result,
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "1.6.6",
                    "installed": True,
                    "enabled": True,
                    "scope": None,
                }
            ],
        )


if __name__ == "__main__":
    unittest.main()
```

Modify `tests/agent-harnesses.bats` to execute the unit file:

```bash
@test "agent-harnesses: plugin normalizers pass unit tests" {
  run python3 "$HOME/tests/test_agent_plugins.py"

  [ "$status" -eq 0 ]
}
```

- [ ] **Step 3: Run tests to verify the module is missing**

Run:

```bash
bats tests/agent-harnesses.bats --filter 'plugin normalizers'
```

Expected: FAIL with `ModuleNotFoundError: No module named 'agent_plugins'`.

- [ ] **Step 4: Implement tracked configuration normalization**

Create `scripts/agent_plugins.py` with:

```python
#!/usr/bin/env python3
"""Normalize configured and observed plugins across agent harnesses.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tomllib
from typing import Any

HARNESSES = ("claude", "codex")


def configured_plugins(root: Path) -> dict[str, list[dict[str, Any]]]:
    claude_settings = _read_json(root / ".claude" / "settings.json")
    codex_config = _read_toml(root / ".codex" / "config.toml")

    claude_marketplaces = {
        name: _claude_marketplace_source(value)
        for name, value in claude_settings.get(
            "extraKnownMarketplaces", {}
        ).items()
    }
    codex_marketplaces = {
        name: _codex_marketplace_source(value)
        for name, value in codex_config.get("marketplaces", {}).items()
    }

    return {
        "claude": _configured_entries(
            claude_settings.get("enabledPlugins", {}),
            claude_marketplaces,
        ),
        "codex": _configured_entries(
            {
                plugin_id: value.get("enabled", False)
                for plugin_id, value in codex_config.get("plugins", {}).items()
            },
            codex_marketplaces,
        ),
    }


def _configured_entries(
    enabled_plugins: dict[str, Any],
    marketplaces: dict[str, str | None],
) -> list[dict[str, Any]]:
    return [
        {
            "id": plugin_id,
            "enabled": bool(enabled),
            "marketplace": _marketplace_name(plugin_id),
            "marketplace_source": marketplaces.get(
                _marketplace_name(plugin_id)
            ),
        }
        for plugin_id, enabled in sorted(enabled_plugins.items())
    ]


def _marketplace_name(plugin_id: str) -> str:
    return plugin_id.rpartition("@")[2] or ""


def _claude_marketplace_source(value: Any) -> str | None:
    if not isinstance(value, dict):
        return None
    source = value.get("source", {})
    if not isinstance(source, dict):
        return None
    if source.get("source") == "github" and source.get("repo"):
        return f"github:{source['repo']}"
    return source.get("url")


def _codex_marketplace_source(value: Any) -> str | None:
    return value.get("source") if isinstance(value, dict) else None


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text()) if path.exists() else {}


def _read_toml(path: Path) -> dict[str, Any]:
    return tomllib.loads(path.read_text()) if path.exists() else {}
```

- [ ] **Step 5: Implement live schema normalization and audit**

Append to `scripts/agent_plugins.py`:

```python
def normalize_live_plugins(
    harness: str, payload: Any
) -> list[dict[str, Any]]:
    if harness == "claude":
        entries = payload if isinstance(payload, list) else []
        normalized = [
            {
                "id": str(entry.get("id", "")),
                "version": str(entry.get("version", "")),
                "installed": True,
                "enabled": bool(entry.get("enabled", False)),
                "scope": entry.get("scope"),
            }
            for entry in entries
            if isinstance(entry, dict) and entry.get("id")
        ]
    elif harness == "codex":
        installed = payload.get("installed", []) if isinstance(payload, dict) else []
        normalized = [
            {
                "id": str(entry.get("pluginId", "")),
                "version": str(entry.get("version", "")),
                "installed": bool(entry.get("installed", True)),
                "enabled": bool(entry.get("enabled", False)),
                "scope": None,
            }
            for entry in installed
            if isinstance(entry, dict) and entry.get("pluginId")
        ]
    else:
        raise ValueError(f"unsupported harness: {harness}")
    return sorted(normalized, key=lambda entry: entry["id"])


def audit_plugins(
    configured: dict[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    observed = {
        harness: _load_live_plugins(harness)
        for harness in HARNESSES
    }
    drift: list[dict[str, Any]] = []

    for harness in HARNESSES:
        if not observed[harness]["available"]:
            continue
        actual = {
            entry["id"]: entry
            for entry in observed[harness]["plugins"]
        }
        for expected in configured.get(harness, []):
            plugin_id = expected["id"]
            current = actual.get(plugin_id)
            if current is None:
                drift.append(
                    {
                        "harness": harness,
                        "id": plugin_id,
                        "field": "installed",
                        "configured": True,
                        "observed": False,
                    }
                )
            elif current["enabled"] != expected["enabled"]:
                drift.append(
                    {
                        "harness": harness,
                        "id": plugin_id,
                        "field": "enabled",
                        "configured": expected["enabled"],
                        "observed": current["enabled"],
                    }
                )

    return {"observed": observed, "drift": drift}


def _load_live_plugins(harness: str) -> dict[str, Any]:
    if shutil.which(harness) is None:
        return {
            "available": False,
            "plugins": [],
            "error": f"{harness} command not found",
        }
    result = subprocess.run(
        [harness, "plugin", "list", "--json"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        return {
            "available": False,
            "plugins": [],
            "error": result.stderr.strip() or f"{harness} plugin list failed",
        }
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return {
            "available": False,
            "plugins": [],
            "error": f"invalid {harness} plugin JSON: {exc}",
        }
    return {
        "available": True,
        "plugins": normalize_live_plugins(harness, payload),
        "error": "",
    }
```

- [ ] **Step 6: Add unavailable-command coverage**

Add `unittest.mock` to the imports in `tests/test_agent_plugins.py`:

```python
from unittest.mock import patch
```

Add `audit_plugins` to the imported names and append this method to
`LivePluginTests`:

```python
    @patch("agent_plugins.shutil.which", return_value=None)
    def test_audit_marks_missing_commands_unavailable(
        self, _which: object
    ) -> None:
        result = audit_plugins({"claude": [], "codex": []})

        self.assertFalse(result["observed"]["claude"]["available"])
        self.assertFalse(result["observed"]["codex"]["available"])
        self.assertEqual(result["drift"], [])
```

- [ ] **Step 7: Run focused tests**

Run:

```bash
python3 tests/test_agent_plugins.py
bats tests/agent-harnesses.bats --filter 'plugin normalizers'
```

Expected: all plugin-normalizer tests pass.

- [ ] **Step 8: Commit and push the normalization module**

Run:

```bash
git add scripts/agent_plugins.py tests/test_agent_plugins.py tests/agent-harnesses.bats
git diff --cached --check
```

Invoke `$git-commit` with expected subject:

```text
feat(harness): Normalize native plugins
```

Run `git push`. Expected: commit and push succeed.

---

### Task 3: Expose Plugin Configuration and Drift

**Files:**

- Modify: `scripts/agent-harnesses.py`
- Modify: `tests/agent-harnesses.bats`
- Regenerate: `docs/agent-harnesses.json`
- Regenerate: `docs/agent-harnesses.md`
- Regenerate: `.agents/harness/**`
- Regenerate: `.config/opencode/**`
- Regenerate: `.pi/agent/**`

**Interfaces:**

- Consumes: `configured_plugins(ROOT)` and `audit_plugins(inventory["plugins"])`
- Produces: `inventory --json` with `plugins.claude` and `plugins.codex`
- Produces: `audit --json` with `plugins.observed` and `plugins.drift`
- Produces: `docs/agent-harnesses.md` section `## Native Plugins`

- [ ] **Step 1: Add failing integration assertions**

Extend the first inventory test in `tests/agent-harnesses.bats`:

```bash
  claude_plugins=$(printf '%s' "$output" | jq '.plugins.claude | type')
  codex_plugins=$(printf '%s' "$output" | jq '.plugins.codex | type')

  [ "$claude_plugins" = '"array"' ]
  [ "$codex_plugins" = '"array"' ]
```

Add:

```bash
@test "agent-harnesses: generated manifest contains native plugin matrix" {
  run python3 "$SCRIPT" generate
  [ "$status" -eq 0 ]

  jq -e '.plugins.claude and .plugins.codex' \
    "$HOME/docs/agent-harnesses.json" >/dev/null
  grep -Fq '## Native Plugins' "$HOME/docs/agent-harnesses.md"
  grep -Fq '| Plugin | Claude | Codex |' "$HOME/docs/agent-harnesses.md"
}

@test "agent-harnesses: audit reports observed plugins and drift" {
  run python3 "$SCRIPT" audit --json

  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq '.plugins.observed | type')" = '"object"' ]
  [ "$(printf '%s' "$output" | jq '.plugins.drift | type')" = '"array"' ]
}
```

- [ ] **Step 2: Run integration tests to verify they fail**

Run:

```bash
bats tests/agent-harnesses.bats --filter 'native plugin matrix|reports observed plugins'
```

Expected: FAIL because inventory, manifest, and audit do not contain `plugins`.

- [ ] **Step 3: Import the focused plugin module**

Inside the existing non-guard conditional import block in
`scripts/agent-harnesses.py`, add:

```python
    from agent_plugins import audit_plugins, configured_plugins
```

This preserves the low-latency guard path because `agent_plugins` is not loaded
for `guard`.

- [ ] **Step 4: Add configured plugins to inventory and manifest**

Add to the dictionary returned by `build_inventory()`:

```python
        "plugins": configured_plugins(ROOT),
```

Add to the dictionary returned by `build_manifest()`:

```python
        "plugins": inventory["plugins"],
```

For text `inventory` output, append:

```python
        print(
            "plugins: "
            + ", ".join(
                f"{harness}={len(plugins)}"
                for harness, plugins in inventory["plugins"].items()
            )
        )
```

- [ ] **Step 5: Add live state to audit output**

In `command_audit()`, build configured inventory once:

```python
    inventory = build_inventory()
```

Add this key to `audit`:

```python
        "plugins": audit_plugins(inventory["plugins"]),
```

After the version list in non-JSON output, print availability, observed counts,
and drift:

```python
        print("## Native Plugins")
        print()
        for harness, state_data in audit["plugins"]["observed"].items():
            if state_data["available"]:
                print(f"- {harness}: {len(state_data['plugins'])} observed")
            else:
                print(f"- {harness}: unavailable ({state_data['error']})")
        for item in audit["plugins"]["drift"]:
            print(
                "- {harness} {id}: {field} configured={configured} "
                "observed={observed}".format(**item)
            )
        print()
```

- [ ] **Step 6: Render the deterministic plugin matrix**

Before `## Configuration Attribute Mapping` in
`render_manifest_markdown()`, extend `lines` with:

```python
    plugins = manifest["plugins"]
    plugin_ids = sorted(
        {
            entry["id"]
            for harness_entries in plugins.values()
            for entry in harness_entries
        }
    )
    configured_by_harness = {
        harness: {entry["id"]: entry for entry in entries}
        for harness, entries in plugins.items()
    }
    lines.extend(
        [
            "",
            "## Native Plugins",
            "",
            "| Plugin | Claude | Codex |",
            "|---|---|---|",
        ]
    )
    for plugin_id in plugin_ids:
        lines.append(
            "| {plugin} | {claude} | {codex} |".format(
                plugin=escape_markdown_cell(plugin_id),
                claude=format_plugin_state(
                    configured_by_harness["claude"].get(plugin_id)
                ),
                codex=format_plugin_state(
                    configured_by_harness["codex"].get(plugin_id)
                ),
            )
        )
```

Add next to `format_state()`:

```python
def format_plugin_state(value: dict[str, Any] | None) -> str:
    if value is None:
        return "missing"
    return "enabled" if value["enabled"] else "disabled"
```

- [ ] **Step 7: Regenerate and run focused validation**

Run:

```bash
just harness-generate
python3 scripts/agent-harnesses.py inventory --json | jq '.plugins'
python3 scripts/agent-harnesses.py audit --json | jq '.plugins'
bats tests/agent-harnesses.bats
just harness-check
git diff --check
```

Expected:

- JSON contains Claude and Codex configured plugin arrays.
- Audit contains explicit observed availability and a drift array.
- Markdown contains the native plugin matrix.
- Generated-artifact and Antigravity artifact tests now pass.
- Any remaining failure is compared with the recorded baseline and must not be
  caused by plugin inventory.

- [ ] **Step 8: Commit deterministic visibility**

Review all generated changes:

```bash
git status --short
git diff --stat
git diff -- docs/agent-harnesses.json docs/agent-harnesses.md
```

Stage `scripts/agent-harnesses.py`, `tests/agent-harnesses.bats`, and every
changed file emitted by `just harness-generate`. Invoke `$git-commit` with:

```text
feat(harness): Show native plugin drift
```

Run `git push`. Expected: commit and push succeed.

---

### Task 4: Enable Pup in Claude and Codex

**Files:**

- Modify: `.claude/settings.json`
- Modify: `.codex/config.toml`
- Regenerate: `docs/agent-harnesses.json`
- Regenerate: `docs/agent-harnesses.md`

**Interfaces:**

- Consumes: the mise-managed Pup 1.6.6 binary from Task 1
- Consumes: deterministic inventory and live audit from Tasks 2–3
- Produces: enabled `pup@datadog-pup` native plugins in Claude and Codex
- Produces: Claude manifest version `0.25.0` with nine shared skills and Codex
  manifest version `0.62.0` with eleven skills from marketplace tag `v1.6.6`

- [ ] **Step 1: Capture current plugin state**

Run:

```bash
claude plugin list --json | jq '.[] | select(.id == "pup@datadog-pup")'
codex plugin list --json | jq '.installed[] | select(.pluginId == "pup@datadog-pup")'
jq '.enabledPlugins["pup@datadog-pup"] // null' .claude/settings.json
```

Expected:

- Claude reports installed version `0.25.0` and `enabled: false`.
- Codex has no installed Pup entry.
- Tracked Claude settings do not yet enable Pup.

- [ ] **Step 2: Re-enable the existing Claude plugin**

Run:

```bash
claude plugin enable pup@datadog-pup --scope user
```

If `.claude/settings.json` still lacks a Datadog marketplace entry, add:

```json
"datadog-pup": {
  "source": {
    "repo": "DataDog/pup",
    "source": "github"
  }
}
```

under `extraKnownMarketplaces`. Run:

```bash
just format-json
claude plugin list --json \
  | jq -e '.[] | select(.id == "pup@datadog-pup" and .enabled == true)'
```

Expected: Claude reports the same installed version `0.25.0`, now enabled.

- [ ] **Step 3: Register the pinned Codex marketplace**

Run:

```bash
codex plugin marketplace add DataDog/pup --ref v1.6.6 --json
codex plugin marketplace list --json \
  | jq -e '.marketplaces[] | select(.name == "datadog-pup")'
```

Expected: `datadog-pup` is registered from `DataDog/pup`.

Verify the checked-out revision resolves to the release tag:

```bash
marketplace_root=$(codex plugin marketplace list --json \
  | jq -r '.marketplaces[] | select(.name == "datadog-pup") | .root')
git -C "$marketplace_root" rev-parse HEAD
git -C "$marketplace_root" rev-parse 'v1.6.6^{commit}'
```

Expected: both commit hashes are identical. If not, remove the marketplace and
stop:

```bash
codex plugin marketplace remove datadog-pup
```

- [ ] **Step 4: Install and verify the Codex plugin**

Run:

```bash
codex plugin add pup@datadog-pup
codex plugin list --json \
  | jq -e '.installed[] | select(
      .pluginId == "pup@datadog-pup"
      and .installed == true
      and .enabled == true
    )'
```

Expected: Pup is installed and enabled. On failure, run:

```bash
codex plugin remove pup@datadog-pup
codex plugin marketplace remove datadog-pup
```

Leave Claude enabled and mise Pup installed.

- [ ] **Step 5: Verify the full skill sets in both caches**

Run:

```bash
claude_root=$(claude plugin list --json \
  | jq -r '.[] | select(.id == "pup@datadog-pup") | .installPath')
codex_root=$(codex plugin list --json \
  | jq -r '.installed[] | select(.pluginId == "pup@datadog-pup") | .installPath // .source.path // empty')
find "$claude_root/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
find "$codex_root/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
```

Expected for Claude:

```text
dd-apm
dd-code-generation
dd-debugger
dd-docs
dd-file-issue
dd-logs
dd-monitors
dd-pup
dd-symdb
```

Expected for Codex:

```text
dd-apm
dd-code-generation
dd-debugger
dd-docs
dd-file-issue
dd-logs
dd-monitors
dd-pup
dd-symdb
dd-triage-flaky-test
dd-unblock-pr
```

If Codex JSON does not expose an install path, derive `codex_root` from the
marketplace root verified in Step 3 and the plugin manifest's relative root;
do not hardcode a cache version directory.

- [ ] **Step 6: Regenerate tracked parity artifacts**

Run:

```bash
just format
just harness-generate
python3 scripts/agent-harnesses.py inventory --json \
  | jq -e '
      .plugins.claude[] | select(
        .id == "pup@datadog-pup" and .enabled == true
      )
    '
python3 scripts/agent-harnesses.py inventory --json \
  | jq -e '
      .plugins.codex[] | select(
        .id == "pup@datadog-pup" and .enabled == true
      )
    '
python3 scripts/agent-harnesses.py audit --json \
  | jq -e '
      [.plugins.observed.claude.plugins[],
       .plugins.observed.codex.plugins[]]
      | map(select(.id == "pup@datadog-pup"))
      | length == 2
    '
```

Expected: configured inventory shows Pup enabled in both harnesses; live audit
contains both observed entries and no Pup enabled-state drift.

- [ ] **Step 7: Verify apps remain disabled**

Run:

```bash
rg -n '^apps = false$' .codex/config.toml
if codex plugin list --json \
  | jq -e '.installed[] | select(.pluginId == "datadog@openai-curated")' \
  >/dev/null; then exit 1; fi
```

Expected: apps remain false and the Datadog curated app is absent.

- [ ] **Step 8: Commit and push plugin parity**

Run:

```bash
git diff --check
git add .claude/settings.json .codex/config.toml \
  docs/agent-harnesses.json docs/agent-harnesses.md
git diff --cached --check
```

Include any additional deterministic files changed by `just harness-generate`.
Invoke `$git-commit` with:

```text
feat(agents): Enable Pup plugin parity
```

Run `git push`. Expected: commit and push succeed.

---

### Task 5: Run Final Quality Gates

**Files:**

- Verify only; modify a task-owned file only when fixing a regression introduced
  by Tasks 1–4

**Interfaces:**

- Consumes: all preceding commits
- Produces: a clean, pushed branch with verified runtime and no new test failures

- [ ] **Step 1: Run focused runtime checks**

Run:

```bash
zsh -lic 'command -v pup && pup --version'
mise which pup
claude plugin list --json \
  | jq -e '.[] | select(.id == "pup@datadog-pup" and .enabled == true)'
codex plugin list --json \
  | jq -e '.installed[] | select(
      .pluginId == "pup@datadog-pup"
      and .installed == true
      and .enabled == true
    )'
python3 scripts/agent-harnesses.py audit --json | jq '.plugins'
```

Expected: mise Pup 1.6.6 works and both plugins are installed and enabled.

- [ ] **Step 2: Run repository quality gates**

Run:

```bash
just format
just lint
just test
git diff --check
```

Expected:

- Formatting and lint pass.
- Harness generated-artifact tests pass.
- No test failure is introduced beyond the recorded unrelated Nushell
  `nixtest` baseline failure. If that baseline failure remains, record its
  exact output; do not treat it as a Pup regression.

- [ ] **Step 3: Commit any quality-gate normalization**

If `just format` changed task-owned files, review and commit them with
`$git-commit` using:

```text
style: Normalize Pup parity files
```

If no files changed, skip this step.

- [ ] **Step 4: Push and verify the final branch**

Run:

```bash
git push
git status --short --branch
git log --oneline -6
```

Expected: `thursday` is clean, synchronized with `phatblat/thursday`, and
contains the mise migration, plugin visibility, and plugin parity commits.
