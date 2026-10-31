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

ICON = "Icon\r"
GLOB_CHARS = "*?["


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


def parse_excludes(patterns: list[str]) -> tuple[list[str], bool]:
    """Returns (anchored paths without the leading slash, icon flag)."""
    anchored: list[str] = []
    icon = False
    for pat in patterns:
        if pat == ICON:
            icon = True
        elif pat.startswith("/") and not any(c in pat for c in GLOB_CHARS):
            anchored.append(pat[1:])
        else:
            die(f"home-capture: unsupported exclude pattern for home-capture.py: {pat!r}")
    return anchored, icon


def excluded(path: str, anchored: list[str], icon: bool) -> bool:
    if any(path == x or path.startswith(x + "/") for x in anchored):
        return True
    return icon and ICON in path.split("/")


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

    walked = cfg["~"]
    source_root = Path(os.path.expanduser(walked["source"]))
    anchored, icon = parse_excludes(walked.get("exclude", []))

    conflicts: list[str] = []
    captured = 0

    # Copy-class capture: the live file always wins, it is app-owned.
    for key, entry in cfg.items():
        if key == "~" or entry.get("mode") != "copy":
            continue
        target = Path(os.path.expanduser(key))
        source = Path(os.path.expanduser(entry["source"]))
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

    # Replaced-link scan.
    ls = git(source_root, "ls-files", "-s", "-z", capture=True)
    if ls.returncode != 0:
        die(f"home-capture: git ls-files failed in {source_root}: {ls.stderr.decode().strip()}")
    restore: list[str] = []
    for rec in ls.stdout.decode().split("\0"):
        if not rec:
            continue
        meta, path = rec.split("\t", 1)
        mode = meta.split()[0]
        if excluded(path, anchored, icon):
            continue
        h = home / path
        if mode == "120000":
            if h.is_dir() and not h.is_symlink():
                conflicts.append(f"{path}: directory where a symlink belongs")
            continue
        if h.is_symlink():
            continue
        if h.is_dir():
            conflicts.append(f"{path}: directory where a file belongs")
            continue
        if not h.is_file():
            continue
        src = source_root / path
        if same_bytes(h, src):
            restore.append(path)
            continue
        dirty = git(source_root, "diff", "--quiet", "--", path).returncode != 0
        if dirty:
            conflicts.append(f"{path}: changed in both $HOME and the repo")
            continue
        if not dry:
            shutil.copyfile(h, src)
        print(f"{verb}captured ~/{path}")
        restore.append(path)

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

    mise = shutil.which("mise") or str(home / ".local" / "bin" / "mise")
    rc = subprocess.run([mise, "dot", "apply", "--force", "--yes"], cwd=home, check=False).returncode
    print(summary)
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
