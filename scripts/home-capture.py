#!/usr/bin/env python3
"""home-capture: reconcile $HOME with the primary dotfiles checkout.

Two jobs, driven by the deploy spec ~/.config/mise/conf.d/dotfiles.toml:

1. Copy-class files (apps rewrite these in place): copy the live file in $HOME
   back into the repo so it can be committed.
2. Replaced links: when an app or editor swapped a deployed link for a regular
   file, copy the new bytes into the repo and restore the link through
   `mise dot apply --force`. Refuses (exit 1) whenever that could lose data.

Usage: home-capture.py [--dry-run]

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path


def die(msg: str, code: int = 2) -> None:
    print(msg, file=sys.stderr)
    raise SystemExit(code)


def config_path(home: Path) -> Path:
    env = os.environ
    if env.get("MISE_CONFIG_DIR"):
        base = Path(env["MISE_CONFIG_DIR"])
    elif env.get("XDG_CONFIG_HOME"):
        base = Path(env["XDG_CONFIG_HOME"]) / "mise"
    else:
        base = home / ".config" / "mise"
    return base / "conf.d" / "dotfiles.toml"


def git(source_root: Path, *args: str, capture: bool = False) -> subprocess.CompletedProcess:
    env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_") or k.startswith("GIT_CONFIG")}
    return subprocess.run(["git", "-C", str(source_root), *args], env=env, capture_output=capture, check=False)


def same_bytes(a: Path, b: Path) -> bool:
    return b.is_file() and a.read_bytes() == b.read_bytes()


def main() -> int:
    ap = argparse.ArgumentParser(description="Reconcile $HOME with the primary dotfiles checkout.")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    dry = args.dry_run
    verb = "would " if dry else ""

    home = Path(os.environ["HOME"])
    cfg_file = config_path(home)
    if not cfg_file.is_file():
        die(f"home-capture: {cfg_file} not found")
    cfg = tomllib.loads(cfg_file.read_text())["dotfiles"]

    conflicts: list[str] = []
    captured = 0
    restore: list[str] = []

    # The generated spec (scripts/home_spec.py) has one entry per deployed path,
    # so what it lists is exactly what this script may touch.
    for key, entry in cfg.items():
        if not key.startswith("~/"):
            continue
        rel = key[2:]
        source = Path(os.path.expanduser(entry["source"]))
        target = home / rel
        mode = entry.get("mode")

        # Copy-class capture: the live file always wins, it is app-owned.
        if mode == "copy":
            if target.is_symlink() or not os.path.lexists(target):
                continue
            if target.is_dir():
                conflicts.append(f"{key}: directory where a copied file belongs")
                continue
            if not same_bytes(target, source):
                if not dry:
                    shutil.copyfile(target, source)
                print(f"{verb}captured {key}")
                captured += 1
            continue

        # Replaced-link scan: only links into the repo checkout. Out-of-repo
        # links (relative = true) point at sources this script must not write.
        if mode != "symlink" or entry.get("relative", False) or not str(source).endswith("/" + rel):
            continue
        if source.is_symlink():
            if target.is_dir() and not target.is_symlink():
                conflicts.append(f"{rel}: directory where a symlink belongs")
            continue
        if target.is_symlink():
            continue
        if target.is_dir():
            conflicts.append(f"{rel}: directory where a file belongs")
            continue
        if not target.is_file():
            continue
        if same_bytes(target, source):
            restore.append(rel)
            continue
        source_root = Path(str(source)[: -len(rel) - 1])
        dirty = git(source_root, "diff", "--quiet", "--", rel).returncode != 0
        if dirty:
            conflicts.append(f"{rel}: changed in both $HOME and the repo")
            continue
        if not dry:
            shutil.copyfile(target, source)
        print(f"{verb}captured ~/{rel}")
        restore.append(rel)

    if dry:
        for path in restore:
            print(f"would restore ~/{path}")
    summary = f"home-capture: {captured} copy-class captured, {len(restore)} links restored, {len(conflicts)} conflicts"
    if conflicts:
        for msg in conflicts:
            print(f"conflict: {msg}", file=sys.stderr)
        print(summary)
        return 1
    if dry or not restore:
        print(summary)
        return 0

    # --force overwrites every conflicting entry it is asked to apply, so name
    # exactly the targets scanned above; the spec's other entries are untouched.
    mise = shutil.which("mise") or str(home / ".local" / "bin" / "mise")
    targets = [str(home / rel) for rel in restore]
    rc = subprocess.run([mise, "dot", "apply", "--force", "--yes", *targets], cwd=home, check=False).returncode
    print(summary)
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
