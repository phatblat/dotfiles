"""Shared MCP servers and tool-permission baseline for every harness.

Copyright: Ben Chatelain. Apache 2.0.

Control plane: an agent able to edit this file grants itself permissions on
every harness at the next `just harness-generate`. Human-only, enforced by
`[control_plane]` in `~/.config/ness/policy.toml`.

The approval baseline lives in `[approval]` of that policy file; this module
is the renderer (`bash_rules(style)`). `load_approval()` reads the checkout's
policy.toml directly, without the `applied.json` hash check the guard applies:
the rendered permission files trust the tracked file, as the hardcoded tuples
did before. Imported only from agent-harnesses.py's non-fast-path block, so it
never reaches a guard decision.

Every value here is portable across machines or resolved from the environment:
MCP credentials are never literals (capability `mcp.credential_scope`, p0).
"""

from __future__ import annotations

import copy
import json
import tomllib
from functools import cache
from pathlib import Path
from typing import Any

# Shared MCP servers, rendered into every harness that has a verified consumer.
# stdio entries use `npx -y` so no global install is assumed. `filesystem`'s
# root is $HOME because this repository is checked out AT $HOME.
MCP_SERVERS: dict[str, dict[str, Any]] = {
    "filesystem": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/phatblat"],
    },
}

# The approval baseline lives with the rest of the safety policy
# (decision 2026-10-17-ness-policy-as-data). Read from the repo checkout so a
# worktree renders its own branch's policy, not $HOME's.
POLICY_PATH = (
    Path(__file__).resolve().parent.parent / ".config" / "ness" / "policy.toml"
)


@cache
def load_approval() -> dict[str, Any]:
    with POLICY_PATH.open("rb") as fh:
        return tomllib.load(fh)["approval"]


# omp only: `rm` targets that could escape /tmp or expand unexpectedly. These
# must precede BASH_ALLOW_RM_TMP, since omp matches first-wins.
BASH_ASK_RM_RISKY: tuple[str, ...] = (
    "rm *..*",
    "rm *~*",
    "rm *$*",
    "rm *`*",
    "rm /tmp/",
    "rm * /tmp/",
    "rm /tmp/* *",
    "rm * /tmp/* *",
)

# omp only: allow `rm` under /tmp without a prompt. The combined force +
# recursive spellings are left out on purpose: the shared guard's
# [commands.dangerous] denies them before omp's pattern matters.
BASH_ALLOW_RM_TMP: tuple[str, ...] = (
    "rm /tmp/*",
    "rm -f /tmp/*",
    "rm -r /tmp/*",
)


def _modes() -> dict[str, str]:
    return load_approval()["modes"]


# Kept as module attributes for harness-apply.py and any other importer.
CLAUDE_DEFAULT_MODE = _modes()["claude_default_mode"]
OMP_APPROVAL_MODE = _modes()["omp_approval_mode"]
OPENCODE_EDIT = _modes()["opencode_edit"]
OPENCODE_EXTERNAL_DIRECTORY = _modes()["opencode_external_directory"]
OPENCODE_WEBFETCH = _modes()["opencode_webfetch"]

# Schema URL OMP itself writes into the MCP files it manages
# (`omp://mcp-config.md`). Emitted only for the OMP and pi targets.
OMP_MCP_SCHEMA = (
    "https://raw.githubusercontent.com/can1357/oh-my-pi/main"
    "/packages/coding-agent/src/config/mcp-schema.json"
)


def mcp_json(*, schema: str | None = None) -> str:
    """Render MCP_SERVERS as a `{"mcpServers": {...}}` document."""
    document: dict[str, Any] = {}
    if schema is not None:
        document["$schema"] = schema
    document["mcpServers"] = MCP_SERVERS
    return json.dumps(document, indent=2, sort_keys=True) + "\n"


def mcp_servers_block() -> dict[str, Any]:
    """Return the raw `mcpServers` mapping for merge-based renderers."""
    return copy.deepcopy(MCP_SERVERS)


def mcp_opencode_block() -> dict[str, Any]:
    """Render MCP_SERVERS in opencode's `mcp` schema (McpLocalConfig)."""
    block: dict[str, Any] = {}
    for name, server in MCP_SERVERS.items():
        if server.get("type") == "http":
            block[name] = {
                "type": "remote",
                "url": server["url"],
                "enabled": True,
            }
        else:
            block[name] = {
                "type": "local",
                "command": [server["command"], *server.get("args", [])],
                "enabled": True,
            }
    return block


def bash_rules(style: str) -> Any:
    """Render the permission baseline in one harness's native shape."""
    a = load_approval()
    allow_prefix: list[str] = a["allow_prefix"]
    allow_exact: list[str] = a["allow_exact"]
    prompt_prefix: list[str] = a["prompt_prefix"]
    deny_prefix: list[str] = a["deny_prefix"]

    if style == "claude":
        rules = [f"Bash({cmd} *)" for cmd in allow_prefix]
        rules += [f"Bash({cmd})" for cmd in allow_exact]
        rules += [
            f"WebFetch(domain:{domain})" for domain in a["claude"]["webfetch_domains"]
        ]
        rules += list(a["claude"]["tools"])
        return sorted(rules)

    if style == "claude-deny":
        return [f"Bash({cmd} *)" for cmd in deny_prefix]

    if style == "antigravity":
        return sorted(f"command({cmd})" for cmd in (*allow_prefix, *allow_exact))

    if style == "opencode":
        opencode_rules: dict[str, str] = {}
        for cmd in allow_prefix:
            opencode_rules[f"{cmd}*"] = "allow"
        for cmd in allow_exact:
            opencode_rules[cmd] = "allow"
        for cmd in prompt_prefix:
            opencode_rules[f"{cmd} *"] = "ask"
        for cmd in deny_prefix:
            opencode_rules[f"{cmd} *"] = "deny"
        return opencode_rules

    if style == "omp":
        # First-match-wins: deny, then prompt, then allow. omp accepts only
        # allow|deny|prompt and silently drops any other value.
        patterns: list[dict[str, str]] = []
        for cmd in deny_prefix:
            patterns.append({"match": f"{cmd} *", "approval": "deny"})
            patterns.append({"match": cmd, "approval": "deny"})
        for match in BASH_ASK_RM_RISKY:
            patterns.append({"match": match, "approval": "prompt"})
        for match in BASH_ALLOW_RM_TMP:
            patterns.append({"match": match, "approval": "allow"})
        for cmd in prompt_prefix:
            patterns.append({"match": f"{cmd} *", "approval": "prompt"})
            patterns.append({"match": cmd, "approval": "prompt"})
        for cmd in allow_prefix:
            patterns.append({"match": f"{cmd}*", "approval": "allow"})
        for cmd in allow_exact:
            patterns.append({"match": cmd, "approval": "allow"})
        return patterns

    raise ValueError(f"unknown bash rule style: {style!r}")
