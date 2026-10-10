#!/usr/bin/env python3
"""Check, install, update, and lock Antigravity (agy) plugins.

agy copies a plugin directory into ~/.gemini/config/plugins/<name> once, at
`agy plugin install` time, and records nothing in this repo. So regenerating
the shared adapter (~/.agents/harness/adapters/antigravity) is invisible to
agy, and the versions of the plugins agy ships with are not tracked anywhere.

This script closes both gaps:

  check    exit 1 if the installed plugins differ from the tracked lock file,
           or the installed shared-agent-harness copy differs from the adapter
  install  `agy plugin install` the adapter (idempotent; it copies verbatim)
  update   install, then refresh the lock file
  lock     refresh the lock file from what is installed right now

The lock file (.agents/harness/agy-plugins.lock.json) is deterministic: names,
versions, enabled state, skill counts, and a content hash of the adapter copy.
It carries no timestamps, paths, or machine identity. Bundled plugins (science,
firebase, ...) ship with agy and change when agy upgrades, so a `check` failure
after an agy upgrade means "review, then `lock`", not "something is broken".

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
PLUGINS_DIR = HOME / ".gemini" / "config" / "plugins"
CONFIG_JSON = HOME / ".gemini" / "config" / "config.json"
ADAPTER = HOME / ".agents" / "harness" / "adapters" / "antigravity"
LOCK = HOME / ".agents" / "harness" / "agy-plugins.lock.json"
ADAPTER_PLUGIN = "shared-agent-harness"
IGNORED = {".DS_Store"}


def read_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def tree_sha256(root: Path) -> str:
    """Hash every file's relative path and content, in sorted order."""
    digest = hashlib.sha256()
    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        if path.name in IGNORED:
            continue
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(b"\0")
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    return digest.hexdigest()


def snapshot() -> dict:
    """Describe the installed plugins deterministically."""
    enabled = read_json(CONFIG_JSON).get("plugins", {})
    plugins = {}
    if PLUGINS_DIR.is_dir():
        for directory in sorted(p for p in PLUGINS_DIR.iterdir() if p.is_dir()):
            manifest = read_json(directory / "plugin.json")
            entry = {
                "version": manifest.get("version", ""),
                "installed_version": read_json(directory / "installed_version.json").get(
                    "version", ""
                ),
                "enabled": enabled.get(directory.name, {}).get("enabled", True),
                "skills": sum(1 for _ in directory.glob("skills/**/SKILL.md")),
            }
            if directory.name == ADAPTER_PLUGIN:
                entry["tree_sha256"] = tree_sha256(directory)
            plugins[directory.name] = entry
    return {"plugins": plugins}


def diff(old: dict, new: dict) -> list[str]:
    problems = []
    old_p, new_p = old.get("plugins", {}), new.get("plugins", {})
    for name in sorted(old_p.keys() | new_p.keys()):
        if name not in new_p:
            problems.append(f"{name}: in lock, not installed")
        elif name not in old_p:
            problems.append(f"{name}: installed, not in lock")
        else:
            for key in sorted(old_p[name].keys() | new_p[name].keys()):
                before, after = old_p[name].get(key), new_p[name].get(key)
                if before != after:
                    problems.append(f"{name}.{key}: lock={before!r} installed={after!r}")
    return problems


def adapter_drift() -> list[str]:
    if not ADAPTER.is_dir():
        return [f"adapter missing: {ADAPTER}"]
    installed = PLUGINS_DIR / ADAPTER_PLUGIN
    if not installed.is_dir():
        return [f"{ADAPTER_PLUGIN}: adapter not installed (run: just agy-plugins-install)"]
    if tree_sha256(ADAPTER) != tree_sha256(installed):
        return [
            (
                f"{ADAPTER_PLUGIN}: installed copy differs from the generated adapter "
                "(run: just agy-plugins-update)"
            )
        ]
    return []


def cmd_check(_: argparse.Namespace) -> int:
    problems = adapter_drift()
    if not LOCK.is_file():
        problems.append(f"no lock file at {LOCK} (run: just agy-plugins-lock)")
    else:
        problems += diff(read_json(LOCK), snapshot())
    for problem in problems:
        print(problem)
    if problems:
        return 1
    print(f"agy plugins match {LOCK.name} and the generated adapter")
    return 0


def cmd_install(_: argparse.Namespace) -> int:
    if shutil.which("agy") is None:
        print("agy is not on PATH", file=sys.stderr)
        return 1
    if not ADAPTER.is_dir():
        print(f"adapter missing: {ADAPTER} (run: just harness-generate)", file=sys.stderr)
        return 1
    result = subprocess.run(["agy", "plugin", "install", str(ADAPTER)], check=False)
    return result.returncode


def cmd_lock(_: argparse.Namespace) -> int:
    LOCK.write_text(json.dumps(snapshot(), indent=2, sort_keys=True) + "\n")
    print(f"wrote {LOCK}")
    return 0


def cmd_update(args: argparse.Namespace) -> int:
    return cmd_install(args) or cmd_lock(args)


def main() -> int:
    parser = argparse.ArgumentParser(description=(__doc__ or "").splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    for name, func in (
        ("check", cmd_check),
        ("install", cmd_install),
        ("update", cmd_update),
        ("lock", cmd_lock),
    ):
        sub.add_parser(name).set_defaults(func=func)
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
