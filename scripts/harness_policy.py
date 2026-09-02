"""Shared MCP servers and tool-permission baseline for every harness.

Copyright: Ben Chatelain. Apache 2.0.

Control plane: an agent able to edit this file grants itself permissions on
every harness at the next `just harness-generate`. Human-only, enforced by
`~/.agents/harness/hooks/safety.py` `_CONTROL_PLANE_FRAGMENTS`.

Split out of scripts/agent-harnesses.py so the data is reviewable on its own,
following the harness_capabilities.py precedent. Imported only from
agent-harnesses.py's non-fast-path block, so it never reaches a guard decision.

Every value here is portable across machines or resolved from the environment:
MCP credentials are never literals (capability `mcp.credential_scope`, p0).
"""

from __future__ import annotations

import copy
import json
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

# Command prefixes auto-approved everywhere. A prefix entry allows the command
# and any arguments; an exact entry allows only the bare command line.
BASH_ALLOW_PREFIX: tuple[str, ...] = (
    "[",
    "awk",
    "basename",
    "brew outdated",
    "brew update",
    "brew upgrade",
    "cargo check",
    "cargo clippy",
    "cargo fmt",
    "cargo test",
    "cat",
    "cmp",
    "command -v",
    "ctx7",
    "cut",
    "date",
    "diff",
    "dirname",
    "du",
    "echo",
    "fd",
    "file",
    "find",
    "gh api",
    "gh issue",
    "gh pr create",
    "gh pr edit",
    "gh pr list",
    "gh pr view",
    "gh run",
    "gh search",
    "gh stack",
    "git add",
    "git branch",
    "git check-ignore",
    "git checkout",
    "git commit",
    "git diff",
    "git fetch",
    "git log",
    "git ls-remote",
    "git merge --ff-only",
    "git pull",
    "git push",
    "git rebase",
    "git remote",
    "git rev-list",
    "git rev-parse",
    "git show",
    "git stash",
    "git status",
    "git switch",
    "git symbolic-ref",
    "git tag",
    "git worktree",
    "go build",
    "go test",
    "go vet",
    "grep",
    "head",
    "jq",
    "just",
    "linear",
    "ls",
    "make",
    "mise current",
    "mise install",
    "mise ls",
    "mise search",
    "mise self-update",
    "mise upgrade",
    "mise use",
    "npm run",
    "npm test",
    "npx tsc",
    "pip",
    "pnpm",
    "poetry",
    "prettier",
    "printenv",
    "printf",
    "ps",
    "python3",
    "readlink",
    "realpath",
    "rg",
    "ruff",
    "sed",
    "seq",
    "sg",
    "shellcheck",
    "shfmt",
    "sleep",
    "sort",
    "stat",
    "tail",
    "tee",
    "test",
    "timeout",
    "tr",
    "tree",
    "typos",
    "uniq",
    "uv tool upgrade",
    "wc",
    "which",
    "xargs",
    "yamllint",
    "yarn",
    "yq",
    "~/scripts/sort-gitignore",
)

BASH_ALLOW_EXACT: tuple[str, ...] = (
    "claude mcp list",
    "env",
    "pwd",
    "true",
)

# Prompt even where the mode would auto-approve.
BASH_ASK_PREFIX: tuple[str, ...] = ("rm",)

# Absolute deny, matching the shared guard's privilege-escalation rule.
BASH_DENY_PREFIX: tuple[str, ...] = ("sudo",)

# Non-Bash Claude-style rules; only Claude has a surface for these.
WEBFETCH_ALLOW_DOMAINS: tuple[str, ...] = ("docs.basedpyright.com", "github.com")
CLAUDE_TOOL_ALLOW: tuple[str, ...] = (
    "WebSearch",
    "mcp__acp__Bash",
    "mcp__acp__Edit",
    "mcp__acp__Write",
)

# Per-harness default approval posture.
CLAUDE_DEFAULT_MODE = "auto"
OMP_APPROVAL_MODE = "write"
OPENCODE_EDIT = "ask"
OPENCODE_EXTERNAL_DIRECTORY = "ask"
OPENCODE_WEBFETCH = "ask"

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
    if style == "claude":
        rules = [f"Bash({cmd} *)" for cmd in BASH_ALLOW_PREFIX]
        rules += [f"Bash({cmd})" for cmd in BASH_ALLOW_EXACT]
        rules += [f"WebFetch(domain:{domain})" for domain in WEBFETCH_ALLOW_DOMAINS]
        rules += list(CLAUDE_TOOL_ALLOW)
        return sorted(rules)

    if style == "claude-deny":
        return [f"Bash({cmd} *)" for cmd in BASH_DENY_PREFIX]

    if style == "antigravity":
        rules = [
            f"unsandboxed({cmd})" for cmd in (*BASH_ALLOW_PREFIX, *BASH_ALLOW_EXACT)
        ]
        return sorted(rules)

    if style == "opencode":
        rules: dict[str, str] = {}
        for cmd in BASH_ALLOW_PREFIX:
            rules[f"{cmd}*"] = "allow"
        for cmd in BASH_ALLOW_EXACT:
            rules[cmd] = "allow"
        for cmd in BASH_ASK_PREFIX:
            rules[f"{cmd} *"] = "ask"
        for cmd in BASH_DENY_PREFIX:
            rules[f"{cmd} *"] = "deny"
        return rules

    if style == "omp":
        # First-match-wins: deny, then ask, then allow.
        patterns: list[dict[str, str]] = []
        for cmd in BASH_DENY_PREFIX:
            patterns.append({"match": f"{cmd} *", "approval": "deny"})
            patterns.append({"match": cmd, "approval": "deny"})
        for cmd in BASH_ASK_PREFIX:
            patterns.append({"match": f"{cmd} *", "approval": "ask"})
            patterns.append({"match": cmd, "approval": "ask"})
        for cmd in BASH_ALLOW_PREFIX:
            patterns.append({"match": f"{cmd}*", "approval": "allow"})
        for cmd in BASH_ALLOW_EXACT:
            patterns.append({"match": cmd, "approval": "allow"})
        return patterns

    raise ValueError(f"unknown bash rule style: {style!r}")
