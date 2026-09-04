#!/usr/bin/env python3
"""Apply the shared harness_policy baseline to surfaces `generate` cannot own.

Copyright: Ben Chatelain. Apache 2.0.

`scripts/agent-harnesses.py generate` renders every artifact declaratively:
read the source, write the target, done. Two surfaces cannot work that way
because they are owned by another process at runtime:

- Claude's real MCP registrations live in `~/.claude.json`, which the `claude`
  CLI itself rewrites (health checks, connection state) on every launch.
  Generating that file would fight the CLI; `claude mcp add-json` is the
  supported mutation path instead.
- OMP rewrites `~/.omp/agent/config.yml` with its own YAML emitter on every
  settings change (the reason the `yaml-normalize` clean filter exists).
  Generating it would make `generate --check` fail after any `/settings`
  change; `omp config set` is the supported mutation path instead.

Both subcommands are therefore idempotent CLI drivers over `harness_policy`,
run by `just harness-mcp-apply` / `just harness-perms-apply`, not part of
`render_all()`.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness_policy import MCP_SERVERS, OMP_APPROVAL_MODE, bash_rules


def command_mcp() -> int:
    """Register every MCP_SERVERS entry in Claude's user scope, skipping existing ones."""
    listed = subprocess.run(
        ["claude", "mcp", "list"], capture_output=True, text=True, check=False
    )
    if listed.returncode != 0:
        print(listed.stderr.strip(), file=sys.stderr)
        return 1
    existing = {
        line.split(":", 1)[0].strip()
        for line in listed.stdout.splitlines()
        if ":" in line
    }

    failed = False
    for name, server in MCP_SERVERS.items():
        if name in existing:
            print(f"{name}: already present")
            continue
        added = subprocess.run(
            ["claude", "mcp", "add-json", "--scope", "user", name, json.dumps(server)],
            capture_output=True,
            text=True,
            check=False,
        )
        if added.returncode != 0:
            print(f"{name}: {added.stderr.strip()}", file=sys.stderr)
            failed = True
            continue
        print(f"{name}: added")
    return 1 if failed else 0


def command_perms() -> int:
    """Apply the shared approval mode and bash-pattern baseline to OMP's config."""
    mode = subprocess.run(
        ["omp", "config", "set", "tools.approvalMode", OMP_APPROVAL_MODE],
        capture_output=True,
        text=True,
        check=False,
    )
    if mode.returncode != 0:
        print(mode.stderr.strip(), file=sys.stderr)
        return 1

    patterns = bash_rules("omp")
    patterns_result = subprocess.run(
        ["omp", "config", "set", "bash.patterns", json.dumps(patterns)],
        capture_output=True,
        text=True,
        check=False,
    )
    if patterns_result.returncode != 0:
        print(patterns_result.stderr.strip(), file=sys.stderr)
        return 1

    print(f"tools.approvalMode: {OMP_APPROVAL_MODE}")
    print(f"bash.patterns: {len(patterns)} entries")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=["mcp", "perms"])
    args = parser.parse_args()
    if args.target == "mcp":
        return command_mcp()
    return command_perms()


if __name__ == "__main__":
    raise SystemExit(main())
