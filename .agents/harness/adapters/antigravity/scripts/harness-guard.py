#!/usr/bin/env python3
"""Antigravity wrapper for the shared agent harness guard.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys


def main() -> int:
    payload = json.load(sys.stdin)
    tool = str(payload.get("tool", ""))
    command = str(payload.get("command", ""))
    path = str(payload.get("path", ""))
    content = str(payload.get("content", ""))
    cwd = str(payload.get("cwd", ""))
    script = Path.home() / "scripts" / "agent-harnesses.py"
    args = [
        "python3",
        str(script),
        "guard",
        "--harness",
        "antigravity",
        "--tool",
        tool,
        "--command",
        command,
        "--path",
        path,
        "--content",
        content,
    ]
    if cwd:
        args.extend(["--cwd", cwd])
    result = subprocess.run(
        args,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    print(result.stdout, end="")
    if result.stdout:
        return result.returncode
    print(
        json.dumps(
            {
                "harness": "antigravity",
                "tool": tool,
                "decision": "deny",
                "reason": "Shared guard failed closed",
            },
            sort_keys=True,
        )
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
