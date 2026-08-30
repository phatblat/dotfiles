#!/usr/bin/env python3
"""Differential parity check between the Python and Rust guard implementations.

Runs every corpus case in `crates/ness/tests/corpus/*.json` through both
`python3 scripts/agent-harnesses.py guard` and `ness guard`, and asserts the
emitted `decision` and `reason` fields are identical. Any single mismatch
fails the check — this is a security policy, not a place for "close enough".

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "crates" / "ness" / "tests" / "corpus"
PY_SCRIPT = ROOT / "scripts" / "agent-harnesses.py"
NESS = ROOT / "crates" / "ness" / "target" / "release" / "ness"


def build_args(case: dict) -> list[str]:
    args = ["--harness", case["harness"], "--tool", case["tool"]]
    for flag, key in (
        ("--command", "command"),
        ("--path", "path"),
        ("--content", "content"),
        ("--cwd", "cwd"),
    ):
        value = case.get(key)
        if value is not None:
            args += [flag, value]
    return args


def run(binary: list[str], args: list[str]) -> dict:
    result = subprocess.run(
        [*binary, *args],
        capture_output=True,
        text=True,
        check=False,
        cwd=str(ROOT),
    )
    try:
        return json.loads(result.stdout.strip() or "{}")
    except json.JSONDecodeError:
        return {
            "decision": "<parse-error>",
            "reason": f"stdout={result.stdout!r} stderr={result.stderr!r}",
        }


def main() -> int:
    if not NESS.exists():
        print(
            f"ness binary not found at {NESS}; run `just ness-build` first.",
            file=sys.stderr,
        )
        return 1

    cases = sorted(CORPUS.glob("*.json"))
    if not cases:
        print(f"no corpus cases found under {CORPUS}", file=sys.stderr)
        return 1

    failures: list[tuple[str, tuple, tuple]] = []
    for case_path in cases:
        case = json.loads(case_path.read_text())
        args = build_args(case)
        py_result = run(["python3", str(PY_SCRIPT), "guard"], args)
        ness_result = run([str(NESS), "guard"], args)
        py_pair = (py_result.get("decision"), py_result.get("reason"))
        ness_pair = (ness_result.get("decision"), ness_result.get("reason"))
        if py_pair != ness_pair:
            failures.append((case_path.name, py_pair, ness_pair))

    if failures:
        print(f"{len(failures)} of {len(cases)} corpus cases mismatched:\n")
        for name, py_pair, ness_pair in failures:
            print(f"  {name}")
            print(f"    python3: {py_pair}")
            print(f"    ness:    {ness_pair}")
        return 1

    print(f"all {len(cases)} corpus cases match")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
