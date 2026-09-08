#!/usr/bin/env python3
"""Regenerate ~/Brewfile from current Homebrew installs, curated.

`brew bundle dump` on its own re-adds every formula mise already pins (see
docs/package-management.md) and, on Homebrew 6+, dumps every package manager
extension it can see (VS Code, cargo, go, uv, npm, ...) whether or not this
repo tracks them. This wrapper restricts the dump to taps/formulae/casks/mas,
then prunes the entries listed in .config/homebrew/dump-exclusions.txt.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

sys.dont_write_bytecode = True

HOME = Path(os.environ.get("HOME", str(Path.home()))).resolve()
BREWFILE = HOME / "Brewfile"
EXCLUSIONS = HOME / ".config" / "homebrew" / "dump-exclusions.txt"

VALID_KINDS = {"brew", "cask", "mas"}
ENTRY_RE = re.compile(r'^(tap|brew|cask|mas) "([^"]+)"')

DUMP_ARGS = [
    "brew",
    "bundle",
    "dump",
    "--file=-",
    "--formula",
    "--cask",
    "--tap",
    "--mas",
    "--no-vscode",
    "--no-cargo",
    "--no-go",
    "--no-uv",
    "--no-npm",
    "--no-krew",
    "--no-flatpak",
    "--no-winget",
]


def load_exclusions(path: Path) -> set[tuple[str, str]]:
    """Parse the exclusion manifest into a set of (kind, name) pairs."""
    exclusions: set[tuple[str, str]] = set()
    for lineno, raw in enumerate(path.read_text().splitlines(), start=1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            kind, _, name = line.partition(":")
            if kind not in VALID_KINDS:
                raise ValueError(f"{path}:{lineno}: unknown exclusion type {kind!r}")
        else:
            kind, name = "brew", line
        exclusions.add((kind, name))
    return exclusions


def filter_dump(
    text: str, exclusions: set[tuple[str, str]]
) -> tuple[str, list[tuple[str, str]], set[tuple[str, str]]]:
    """Strip excluded entries (and their preceding comment blocks) from a dump.

    Returns the filtered text, the list of pruned (kind, name) entries in
    dump order, and the subset of `exclusions` that actually matched.
    """
    out: list[str] = []
    buffer: list[str] = []
    pruned: list[tuple[str, str]] = []
    matched: set[tuple[str, str]] = set()

    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("#"):
            buffer.append(line)
            continue
        if not stripped:
            out.extend(buffer)
            buffer = []
            out.append(line)
            continue

        match = ENTRY_RE.match(stripped)
        if not match:
            raise ValueError(f"unexpected line in brew bundle dump output: {line!r}")

        key = (match.group(1), match.group(2))
        if key in exclusions:
            pruned.append(key)
            matched.add(key)
            buffer = []
            continue

        out.extend(buffer)
        buffer = []
        out.append(line)

    out.extend(buffer)
    return "\n".join(out) + "\n", pruned, matched


def main() -> int:
    try:
        result = subprocess.run(
            DUMP_ARGS,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print("ERROR: brew not found on PATH", file=sys.stderr)
        return 1

    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        return 1

    dump = result.stdout

    for lineno, line in enumerate(dump.splitlines(), start=1):
        stripped = line.strip()
        if stripped and not stripped.startswith("#") and not ENTRY_RE.match(stripped):
            print(
                f"ERROR: unexpected line {lineno} in brew bundle dump output: {line!r}",
                file=sys.stderr,
            )
            return 1

    if not EXCLUSIONS.exists():
        print(f"ERROR: exclusion manifest not found at {EXCLUSIONS}", file=sys.stderr)
        return 1

    try:
        exclusions = load_exclusions(EXCLUSIONS)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    filtered, pruned, matched = filter_dump(dump, exclusions)

    tmp = BREWFILE.parent / f"{BREWFILE.name}.tmp"
    tmp.write_text(filtered)
    os.replace(tmp, BREWFILE)

    counts = Counter(kind for kind, _ in pruned)
    print(
        f"pruned {len(pruned)} entries "
        f"({counts.get('brew', 0)} brew, {counts.get('cask', 0)} cask, "
        f"{counts.get('mas', 0)} mas)",
        file=sys.stderr,
    )
    for kind, name in pruned:
        print(f"  {kind}:{name}", file=sys.stderr)

    for kind, name in sorted(exclusions - matched):
        print(f"warning: exclusion never matched: {kind}:{name}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
