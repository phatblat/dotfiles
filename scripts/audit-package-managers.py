#!/usr/bin/env python3
"""Flag CLI tools duplicated across mise and Homebrew.

Strategy (see docs/package-management.md): mise is the primary installer,
Homebrew is the fallback for tools mise can't provide, and Nix/home-manager
is an experiment that intentionally does not need to stay in sync with
either — so it's excluded from this comparison.

This is a basic, name-based audit: it compares mise's declared [tools] keys
against Homebrew's *installed* formulae/casks (not just the Brewfile), since
the most common drift is a brew formula that was installed standalone or
pulled in as a dependency and never added to the Brewfile at all.

Name matching is best-effort — it strips backend prefixes (e.g. "aqua:",
"github:owner/") and compares the final path segment, so it will miss cases
where the mise tool name and the brew formula name differ (e.g. mise's
"jujutsu" provides the `jj` binary that brew calls "jj"). Treat the output
as a starting point for manual review, not a definitive list.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tomllib


sys.dont_write_bytecode = True

HOME = Path(os.environ.get("HOME", str(Path.home()))).resolve()
MISE_CONFIG = HOME / ".config" / "mise" / "config.toml"


def mise_tool_names() -> dict[str, str]:
    """Map normalized short name -> raw mise config key."""
    config = tomllib.loads(MISE_CONFIG.read_text())
    tools = config.get("tools", {})
    names: dict[str, str] = {}
    for raw_key in tools:
        # Strip backend prefix (aqua:, cargo:, github:, npm:, pipx:, go:, ubi:, ...)
        after_backend = raw_key.split(":", 1)[-1]
        # Take the last path segment (owner/repo -> repo)
        short = after_backend.rsplit("/", 1)[-1]
        names[short.lower()] = raw_key
    return names


def brew_installed(kind: str) -> set[str]:
    """Return installed formula or cask names (kind: 'formula' or 'cask')."""
    result = subprocess.run(
        ["brew", "list", f"--{kind}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        check=False,
    )
    return {line.strip().lower() for line in result.stdout.splitlines() if line.strip()}


def brewfile_declared() -> set[str]:
    """Return formula/cask names explicitly listed in ~/Brewfile."""
    brewfile = HOME / "Brewfile"
    if not brewfile.exists():
        return set()
    names: set[str] = set()
    for line in brewfile.read_text().splitlines():
        line = line.strip()
        if line.startswith('brew "') or line.startswith('cask "'):
            name = line.split('"', 2)[1]
            names.add(name.lower())
    return names


def main() -> int:
    if not MISE_CONFIG.exists():
        print(f"ERROR: mise config not found at {MISE_CONFIG}", file=sys.stderr)
        return 1

    mise_names = mise_tool_names()
    formulae = brew_installed("formula")
    casks = brew_installed("cask")
    declared = brewfile_declared()

    overlaps = sorted(set(mise_names) & (formulae | casks))

    if not overlaps:
        print("No name-based overlaps found between mise and installed Homebrew tools.")
        print(
            "(Nix/home-manager is intentionally excluded — see docs/package-management.md)"
        )
        return 0

    print(f"Found {len(overlaps)} tool(s) installed via both mise and Homebrew:\n")
    for name in overlaps:
        kind = "cask" if name in casks and name not in formulae else "formula"
        tracked = (
            "tracked in Brewfile"
            if name in declared
            else "NOT in Brewfile (dependency or stray install)"
        )
        print(f"  {name}")
        print(f"    mise:   {mise_names[name]}")
        print(f"    brew:   {kind}, {tracked}")

    print(
        "\nPer the mise-primary strategy, review each and remove the brew copy"
        " unless something still depends on it (check with `brew uses --installed <name>`)."
    )
    print(
        "Note: name matching misses aliases (e.g. mise's jujutsu -> jj binary) — review manually too."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
