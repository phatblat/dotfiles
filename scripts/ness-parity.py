#!/usr/bin/env python3
"""Differential parity checks between the Python and Rust guard implementations.

Two independent modes, both comparing against the Python reference
(`scripts/agent-harnesses.py`) as ground truth:

`guard` mode runs every corpus case in `crates/ness/tests/corpus/*.json`
through `python3 scripts/agent-harnesses.py guard` and `ness guard`, once for
the freshly built `crates/ness/target/release/ness` and once for every other
`ness` executable found on `PATH` (an installed copy left over from before a
policy change is exactly the kind of drift this catches). Any single mismatch
fails the check — this is a security policy, not a place for "close enough".

`hook` mode differentially tests the four bash shims (`.claude` and `.codex`
`hooks/scripts/{bash,write}-guard.sh`) against themselves: each shim is run
twice with identical stdin, once with a `PATH` that resolves `ness` to the
binary under test and once with a `PATH` that does not, and the two responses
must be identical. This is the only check that exercises payload extraction
and response rendering, and it keeps working after the cutover because the
fallback branch (`python3` + `jq`) is retained. Fixtures come from the corpus
(re-shaped into each shim's native payload) plus
`crates/ness/tests/hook_corpus/*.json`, which covers apply_patch envelopes and
other cases corpus reshaping cannot express.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORPUS = ROOT / "crates" / "ness" / "tests" / "corpus"
HOOK_CORPUS = ROOT / "crates" / "ness" / "tests" / "hook_corpus"
PY_SCRIPT = ROOT / "scripts" / "agent-harnesses.py"
BUILT_NESS = ROOT / "crates" / "ness" / "target" / "release" / "ness"

# tool -> shim key used by hook mode; corpus tools not listed here (e.g.
# "read") are neither guarded by a shim nor represented in tool_input the
# same way, so hook mode skips them rather than guessing a shape.
BASH_SHIMS = {"claude": "claude-bash", "codex": "codex-bash"}
WRITE_SHIMS = {"claude": "claude-write", "codex": "codex-write"}
WRITE_LIKE_TOOLS = {"write", "edit", "multiedit"}

SHIM_PATHS = {
    "claude-bash": ROOT / ".claude" / "hooks" / "scripts" / "bash-guard.sh",
    "claude-write": ROOT / ".claude" / "hooks" / "scripts" / "write-guard.sh",
    "codex-bash": ROOT / ".codex" / "hooks" / "scripts" / "bash-guard.sh",
    "codex-write": ROOT / ".codex" / "hooks" / "scripts" / "write-guard.sh",
}


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


def discover_path_binaries() -> list[Path]:
    """Every executable named `ness` on PATH, deduplicated by real path.

    Not just the first hit: a fresher copy earlier on PATH silently shadowing
    a stale one later on PATH is exactly the drift this exists to catch, so
    every copy is checked, not just the one that would actually run.
    """
    seen: dict[str, Path] = {}
    for directory in os.environ.get("PATH", "").split(":"):
        if not directory:
            continue
        candidate = Path(directory) / "ness"
        if candidate.is_file() and os.access(candidate, os.X_OK):
            real = str(candidate.resolve())
            seen.setdefault(real, candidate)
    return list(seen.values())


def guard_mode_binaries(explicit: list[str] | None = None) -> list[Path]:
    if explicit:
        return [Path(b) for b in explicit]
    if not BUILT_NESS.exists():
        print(
            f"ness binary not found at {BUILT_NESS}; run `just ness-build` first.",
            file=sys.stderr,
        )
        return []
    binaries = [BUILT_NESS]
    built_real = str(BUILT_NESS.resolve())
    for candidate in discover_path_binaries():
        if str(candidate.resolve()) == built_real:
            continue
        binaries.append(candidate)
    for candidate in binaries[1:]:
        print(f"also checking: {candidate}")
    if len(binaries) == 1:
        print("no other ness on PATH; skipping installed-copy check")
    return binaries


def run_guard_mode(explicit: list[str] | None = None) -> list[str]:
    binaries = guard_mode_binaries(explicit)
    if not binaries:
        return ["ness binary not found; see above"]

    cases = sorted(CORPUS.glob("*.json"))
    if not cases:
        return [f"no corpus cases found under {CORPUS}"]

    failures: list[str] = []
    for binary in binaries:
        mismatches = []
        for case_path in cases:
            case = json.loads(case_path.read_text())
            args = build_args(case)
            py_result = run(["python3", str(PY_SCRIPT), "guard"], args)
            ness_result = run([str(binary), "guard"], args)
            py_pair = (py_result.get("decision"), py_result.get("reason"))
            ness_pair = (ness_result.get("decision"), ness_result.get("reason"))
            if py_pair != ness_pair:
                mismatches.append((case_path.name, py_pair, ness_pair))

        if mismatches:
            failures.append(
                f"{binary}: {len(mismatches)} of {len(cases)} corpus cases mismatched"
            )
            for name, py_pair, ness_pair in mismatches:
                failures.append(f"  {name}\n    python3: {py_pair}\n    ness:    {ness_pair}")
        else:
            print(f"guard mode: all {len(cases)} corpus cases match ({binary})")

    return failures


def bash_payload(command: str) -> dict:
    return {
        "hook_event_name": "PreToolUse",
        "tool_name": "Bash",
        "tool_input": {"command": command},
    }


def write_payload(path: str, content: str) -> dict:
    return {
        "hook_event_name": "PreToolUse",
        "tool_name": "Write",
        "tool_input": {"file_path": path, "content": content},
    }


def corpus_hook_fixtures() -> tuple[list[tuple[str, str, dict]], int]:
    """(fixture_name, shim_key, payload) reshaped from every corpus case that
    a bash shim actually guards, plus a skip count for the rest."""
    fixtures: list[tuple[str, str, dict]] = []
    skipped = 0
    for case_path in sorted(CORPUS.glob("*.json")):
        case = json.loads(case_path.read_text())
        tool = case["tool"]
        harness = case["harness"]
        if tool == "bash":
            shim = BASH_SHIMS.get(harness)
            if shim is None:
                skipped += 1
                continue
            fixtures.append((case_path.name, shim, bash_payload(case.get("command") or "")))
        elif tool in WRITE_LIKE_TOOLS:
            shim = WRITE_SHIMS.get(harness)
            if shim is None:
                skipped += 1
                continue
            fixtures.append(
                (
                    case_path.name,
                    shim,
                    write_payload(case.get("path") or "", case.get("content") or ""),
                )
            )
        else:
            skipped += 1
    return fixtures, skipped


def explicit_hook_fixtures() -> list[tuple[str, str, dict]]:
    fixtures = []
    for fixture_path in sorted(HOOK_CORPUS.glob("*.json")):
        fixture = json.loads(fixture_path.read_text())
        fixtures.append((fixture_path.name, fixture["shim"], fixture["payload"]))
    return fixtures


def path_without_ness() -> str:
    kept = []
    for directory in os.environ.get("PATH", "").split(":"):
        if not directory:
            continue
        candidate = Path(directory) / "ness"
        if candidate.is_file() and os.access(candidate, os.X_OK):
            continue
        kept.append(directory)
    return ":".join(kept)


def run_shim(shim_key: str, payload: dict, path_value: str) -> tuple[int, dict | None]:
    shim_path = SHIM_PATHS[shim_key]
    result = subprocess.run(
        ["bash", str(shim_path)],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=False,
        cwd=str(ROOT),
        env={**os.environ, "PATH": path_value},
    )
    stdout = result.stdout.strip()
    try:
        parsed = json.loads(stdout) if stdout else None
    except json.JSONDecodeError:
        parsed = {"<parse-error>": stdout}
    return result.returncode, parsed


def run_hook_mode(explicit: list[str] | None = None) -> list[str]:
    binaries = guard_mode_binaries(explicit)
    if not binaries:
        return ["ness binary not found; see above"]

    corpus_fixtures, skipped = corpus_hook_fixtures()
    fixtures = corpus_fixtures + explicit_hook_fixtures()
    if skipped:
        print(f"hook mode: skipping {skipped} corpus case(s) with no shim mapping")

    base_path_without = path_without_ness()

    failures: list[str] = []
    for binary in binaries:
        ness_dir = tempfile.mkdtemp(prefix="ness-parity-")
        symlink = Path(ness_dir) / "ness"
        symlink.symlink_to(Path(binary).resolve())
        path_with = f"{ness_dir}:{base_path_without}"

        mismatches = []
        for name, shim_key, payload in fixtures:
            status_with, out_with = run_shim(shim_key, payload, path_with)
            status_without, out_without = run_shim(shim_key, payload, base_path_without)
            if status_with != 0 or status_without != 0:
                mismatches.append(
                    f"{name} ({shim_key}): non-zero exit "
                    f"(with-ness={status_with}, without-ness={status_without})"
                )
            elif out_with != out_without:
                mismatches.append(
                    f"{name} ({shim_key})\n"
                    f"    with ness:    {out_with}\n"
                    f"    without ness: {out_without}"
                )

        if mismatches:
            failures.append(f"{binary}: {len(mismatches)} of {len(fixtures)} hook cases mismatched")
            failures.extend(f"  {m}" for m in mismatches)
        else:
            print(f"hook mode: all {len(fixtures)} hook cases match ({binary})")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=["guard", "hook", "both"],
        default="both",
        help="which differential check to run (default: both)",
    )
    parser.add_argument(
        "--binary",
        action="append",
        default=None,
        help=(
            "ness executable to check (repeatable); default checks the freshly "
            "built binary plus every other ness found on PATH"
        ),
    )
    args = parser.parse_args()

    failures: list[str] = []
    if args.mode in ("guard", "both"):
        failures += run_guard_mode(args.binary)
    if args.mode in ("hook", "both"):
        failures += run_hook_mode(args.binary)

    if failures:
        print("\nparity check failed:\n", file=sys.stderr)
        for line in failures:
            print(line, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
