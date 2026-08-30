#!/usr/bin/env python3
"""Crush wrapper for the shared agent harness guard.

Crush sends snake_case PreToolUse payloads (`tool_name`, `tool_input`) and
blocks a call on exit 2, using stderr as the deny reason. Classify by the shape
of `tool_input` so an upstream tool rename cannot silently unhook the guard.

An allowed call stays silent on purpose. Crush reads `{"decision": "allow"}` as
affirmative pre-approval that bypasses its own permission prompt, so echoing
`allow` here would weaken crush's native safety rather than add to it. Exit 0
with no stdout is crush's documented "no opinion", which falls through to the
normal permission flow.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys

PATH_KEYS = ("file_path", "path", "target_file")
CONTENT_KEYS = ("content", "new_string", "new_text", "new_str")


def deny(reason: str) -> int:
    print(reason, file=sys.stderr)
    return 2


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except ValueError as exc:
        return deny(f"shared guard failed closed: unreadable hook payload ({exc})")

    # Require dict payload before extracting tool_input
    if not isinstance(payload, dict):
        return deny("shared guard failed closed: payload is not a dict")

    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        tool_input = {}
    command = tool_input.get("command")
    command = command if isinstance(command, str) else ""
    path = ""
    for key in PATH_KEYS:
        value = tool_input.get(key)
        if isinstance(value, str) and value:
            path = value
            break

    # Collect content from direct keys and flatten nested edits[].new_string
    content_parts = []
    for key in CONTENT_KEYS:
        value = tool_input.get(key)
        if isinstance(value, str):
            content_parts.append(value)

    # Flatten multiedit payloads: extract new_string from edits[]
    edits = tool_input.get("edits")
    if isinstance(edits, list):
        for edit in edits:
            if isinstance(edit, dict):
                for key in CONTENT_KEYS:
                    value = edit.get(key)
                    if isinstance(value, str):
                        content_parts.append(value)

    content = "".join(content_parts)

    if command:
        tool = "bash"
    elif path:
        tool = "write"
    else:
        return 0

    args = [
        "python3",
        str(Path.home() / "scripts" / "agent-harnesses.py"),
        "guard",
        "--harness",
        "crush",
        "--tool",
        tool,
        "--command",
        command,
        "--path",
        path,
        "--content",
        content,
    ]
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd:
        args.extend(["--cwd", cwd])

    try:
        result = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except OSError as exc:
        # E2BIG, missing python3, etc. → fail closed
        return deny(f"shared guard failed closed: {exc}")

    try:
        verdict = json.loads(result.stdout)
    except ValueError:
        detail = result.stderr.strip() or "no guard output"
        return deny(f"shared guard failed closed: {detail}")

    decision = verdict.get("decision", "deny")
    reason = verdict.get("reason", "shared guard failed closed")
    if decision == "deny":
        return deny(reason)
    if decision == "warn" and reason:
        print(reason, file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
