#!/usr/bin/env python3
"""Compare cmux Settings-window preferences with the tracked cmux.json.

cmux keeps Settings-window choices in UserDefaults (com.cmuxterm.app) and
imports ~/.config/cmux/cmux.json into the same keys. At runtime an explicit
Settings choice wins over the imported cmux.json value, so a change made in the
Settings window silently diverges from the tracked file.

    cmux-settings.py check [--verbose]  # exit 1 when Settings drift from cmux.json
    cmux-settings.py fix                # write drifted Settings values into cmux.json

Only keys in cmux's settings catalog are compared. Window geometry, analytics,
identifiers, caches, and other runtime state in the plist are not catalog
settings, so they never appear. Catalog settings that are auth or
machine-specific are excluded below. The catalog (cmux.json path to UserDefaults
key) is parsed from cmux's source at the installed version and cached under
${XDG_CACHE_HOME:-~/.cache}/cmux-settings/.
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, NoReturn

DOMAIN = "com.cmuxterm.app"
REPO_URL = "https://github.com/manaflow-ai/cmux.git"
# Bump when parse_catalog's output changes so stale caches are not reused.
CATALOG_FORMAT = 2
# cmux records the cmux.json values it imported, keyed by UserDefaults key, so it
# can tell an explicit Settings choice apart from its own import.
IMPORTED_KEY = "cmux.settingsFile.importedManagedDefaults.v1"
CMUX_JSON = "~/.config/cmux/cmux.json"

# Catalog settings that stay out of cmux.json, with the reason.
EXCLUDED_PREFIXES = {
    "account.": "sign-in and team identity",
    "devices.": "per-machine device pairing and IDs",
    "mobile.iOSPairingHost.": "per-machine iOS pairing host",
}
EXCLUDED_PATHS = {
    "app.warnBeforeQuit": "legacy fallback superseded by app.confirmQuit",
    "automation.claudeBinaryPath": "machine-specific install path",
    "automation.ripgrepBinaryPath": "machine-specific install path",
    "integrations.claudeCode.customClaudePath": "machine-specific install path",
    "integrations.ripgrep.customBinaryPath": "machine-specific install path",
}
EXCLUDED_SUFFIXES = {
    ".remembered": "runtime width memory, not a preference",
}

# One catalog entry: `DefaultsKey<Type>(id: <literal or Type.member>, ...)`.
KEY_RE = re.compile(r"\bDefaultsKey<[^()\n]*>\(\s*id:\s*(?P<id>[^,\n)]+)")
DEFAULTS_KEY_RE = re.compile(r"userDefaultsKey:\s*(?P<expr>[^,\n)]+)")
SUITE_RE = re.compile(r"^\s*suite:\s*(?P<expr>[^,\n)]+)", re.MULTILINE)
VERSION_RE = re.compile(r"^cmux (?P<version>\S+) \(\d+\) \[(?P<sha>[0-9a-f]+)\]")


class Missing:
    """Marks a UserDefaults key that has no stored value."""

    def __repr__(self) -> str:
        return "<missing>"


MISSING = Missing()


@dataclass(frozen=True)
class CatalogKey:
    path: str
    defaults_key: str


@dataclass(frozen=True)
class Drift:
    kind: str  # untracked | different | manual
    path: str
    settings: Any
    file: Any = MISSING
    target: Any = MISSING


def fail(message: str) -> NoReturn:
    print(f"cmux-settings: {message}", file=sys.stderr)
    raise SystemExit(2)


def exclusion_reason(path: str) -> str | None:
    if path in EXCLUDED_PATHS:
        return EXCLUDED_PATHS[path]
    for prefix, reason in EXCLUDED_PREFIXES.items():
        if path.startswith(prefix):
            return reason
    for suffix, reason in EXCLUDED_SUFFIXES.items():
        if path.endswith(suffix):
            return reason
    return None


def cmux_binary() -> str:
    binary = shutil.which("cmux")
    if binary is None:
        fail("cmux CLI not found on PATH")
    return binary


def installed_version(cmux: str) -> tuple[str, str]:
    output = subprocess.run(
        [cmux, "--version"], capture_output=True, text=True, check=True
    ).stdout
    match = VERSION_RE.match(output.strip())
    if match is None:
        fail(f"unrecognized `cmux --version` output: {output.strip()!r}")
    return match["version"], match["sha"]


def string_value(expr: str, sources: list[str]) -> str | None:
    """Return a Swift string literal, or the literal a `Type.member` constant holds."""
    expr = expr.strip()
    if expr.startswith('"'):
        return expr.strip('"')
    return resolve_constant(expr, sources)


def resolve_constant(expr: str, sources: list[str], depth: int = 0) -> str | None:
    """Resolve `Type.member` to the string literal it is declared as.

    Follows constants that alias another (`static let key = settingsPath`).
    """
    type_name, _, member = expr.rpartition(".")
    declaration = re.compile(
        rf"\b(?:enum|struct|class|extension)\s+{re.escape(type_name)}\b"
    )
    value = re.compile(
        rf"static\s+(?:let|var)\s+{re.escape(member)}\b[^=\n]*=\s*(?P<value>[^\n]+)"
    )
    for source in sources:
        if not declaration.search(source):
            continue
        match = value.search(source)
        if match is None:
            continue
        assigned = match["value"].strip()
        if assigned.startswith('"'):
            return assigned.split('"')[1]
        if depth < 3 and re.fullmatch(r"[A-Za-z_][\w.]*", assigned):
            alias = assigned if "." in assigned else f"{type_name}.{assigned}"
            return resolve_constant(alias, sources, depth + 1)
    return None


def parse_catalog(src: Path) -> list[CatalogKey]:
    packages = src / "Packages" / "macOS"
    keys_dir = packages / "CmuxSettings" / "Sources" / "CmuxSettings" / "Keys"
    sources = [
        path.read_text() for path in sorted(packages.glob("*/Sources/**/*.swift"))
    ]
    catalog: list[CatalogKey] = []
    unresolved: list[str] = []
    for section in sorted(keys_dir.glob("*CatalogSection.swift")):
        text = section.read_text()
        matches = list(KEY_RE.finditer(text))
        ends = [match.start() for match in matches[1:]] + [len(text)]
        for match, end in zip(matches, ends):
            segment = text[match.end() : end].split("userFacing:")[0]
            path = string_value(match["id"], sources)
            expr_match = DEFAULTS_KEY_RE.search(segment)
            defaults_key = expr_match and string_value(expr_match["expr"], sources)
            if path is None or not defaults_key:
                unresolved.append(match["id"].strip())
                continue
            if SUITE_RE.search(segment):
                continue  # stored in another defaults domain
            catalog.append(CatalogKey(path, defaults_key))
    if not catalog:
        fail(f"no settings parsed from {keys_dir}; the catalog layout changed")
    if unresolved:
        print(
            f"cmux-settings: warning: {len(unresolved)} catalog settings have no resolvable "
            f"UserDefaults key and are not compared: {', '.join(unresolved)}",
            file=sys.stderr,
        )
    return catalog


def load_catalog(version: str, sha: str) -> dict[str, CatalogKey]:
    cache_root = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
    cache = (
        cache_root / "cmux-settings" / f"catalog{CATALOG_FORMAT}-{version}-{sha}.json"
    )
    if cache.exists():
        entries = [CatalogKey(**entry) for entry in json.loads(cache.read_text())]
    else:
        print(f"Fetching the cmux v{version} settings catalog...", file=sys.stderr)
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "cmux"
            git = ["git", "-c", "advice.detachedHead=false"]
            clone = [
                "clone",
                "--quiet",
                "--depth",
                "1",
                "--filter=blob:none",
                "--sparse",
            ]
            subprocess.run(
                [*git, *clone, "--branch", f"v{version}", REPO_URL, str(src)],
                check=True,
            )
            sparse = [
                "sparse-checkout",
                "set",
                "--no-cone",
                "/Packages/macOS/*/Sources/",
            ]
            subprocess.run([*git, "-C", str(src), *sparse], check=True)
            head = subprocess.run(
                [*git, "-C", str(src), "rev-parse", "HEAD"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            if not head.startswith(sha):
                fail(
                    f"tag v{version} is {head[:9]}, but the installed cmux was built from {sha}"
                )
            entries = parse_catalog(src)
        cache.parent.mkdir(parents=True, exist_ok=True)
        cache.write_text(
            json.dumps([asdict(entry) for entry in entries], indent=2) + "\n"
        )
    return {entry.defaults_key: entry for entry in entries}


def read_preferences() -> dict[str, Any]:
    # `defaults export` reads through cfprefsd, so unflushed Settings changes count.
    result = subprocess.run(
        ["defaults", "export", DOMAIN, "-"], capture_output=True, check=True
    )
    return plistlib.loads(result.stdout)


def config_get(cmux: str, path: str) -> dict[str, Any] | None:
    """Return `cmux config get --json`, or None when cmux.json has no such setting."""
    result = subprocess.run(
        [cmux, "config", "get", path, "--json"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode == 0:
        return json.loads(result.stdout)
    if "isn't a cmux setting" in result.stderr:
        return None
    fail(f"`cmux config get {path}` failed: {result.stderr.strip()}")


def unwrap(managed: dict[str, Any]) -> tuple[str, Any]:
    """Decode a ManagedSettingsValue such as {"bool": {"_0": true}}."""
    ((kind, payload),) = managed.items()
    return kind, payload.get("_0") if isinstance(payload, dict) else payload


def same(left: Any, right: Any) -> bool:
    if isinstance(left, bool) or isinstance(right, bool):
        return type(left) is type(right) and left == right
    return left == right


def compare(
    key: CatalogKey,
    reading: dict[str, Any],
    settings: Any,
    imported: dict[str, Any],
) -> Drift | None:
    source = reading["source"]
    if source == "settings":
        return Drift("untracked", key.path, reading["value"], target=reading["value"])
    if source != "cmux.json" or key.defaults_key not in imported:
        return None
    file_value = reading["value"]
    kind, imported_value = unwrap(imported[key.defaults_key])
    if isinstance(settings, Missing):
        # cmux re-imports any non-nullable key that goes missing, so only a
        # cleared optional value (a color reset in Settings) can persist.
        if kind == "nullableString" and imported_value is not None:
            return Drift("different", key.path, None, file_value, target=None)
        return None
    if same(settings, imported_value):
        return None
    if same(file_value, imported_value):
        target = settings  # cmux.json stores this setting as-is
    elif isinstance(file_value, bool):
        # A two-state setting UserDefaults encodes differently (minimalMode is
        # "standard"/"minimal"): a changed Settings value is the other state.
        target = not file_value
    else:
        return Drift("manual", key.path, settings, file_value)
    if same(target, file_value):
        return None  # cmux.json already holds it; cmux has not re-imported yet
    return Drift("different", key.path, settings, file_value, target=target)


def analyze(cmux: str) -> tuple[str, list[Drift], int, list[str]]:
    version, sha = installed_version(cmux)
    catalog = load_catalog(version, sha)
    preferences = read_preferences()
    raw_imported = preferences.get(IMPORTED_KEY)
    imported: dict[str, Any] = (
        json.loads(raw_imported) if isinstance(raw_imported, bytes) else {}
    )

    notes: list[str] = []
    candidates: list[CatalogKey] = []
    for defaults_key in sorted(set(preferences) | set(imported)):
        key = catalog.get(defaults_key)
        if key is None:
            continue
        reason = exclusion_reason(key.path)
        if reason:
            notes.append(f"excluded     {key.path}: {reason}")
            continue
        candidates.append(key)

    with ThreadPoolExecutor(max_workers=8) as pool:
        readings = list(pool.map(lambda key: config_get(cmux, key.path), candidates))

    drifts: list[Drift] = []
    compared = 0
    for key, reading in zip(candidates, readings):
        if reading is None:
            notes.append(
                f"no cmux.json {key.path} (UserDefaults {key.defaults_key}) in v{version}"
            )
            continue
        compared += 1
        drift = compare(
            key, reading, preferences.get(key.defaults_key, MISSING), imported
        )
        if drift:
            drifts.append(drift)
    return f"cmux {version} [{sha}]", drifts, compared, notes


def show(value: Any) -> str:
    return "<unset>" if isinstance(value, Missing) else json.dumps(value)


def report(drifts: list[Drift]) -> None:
    for drift in drifts:
        if drift.kind == "untracked":
            print(f"untracked  {drift.path} = {show(drift.target)}")
        elif drift.kind == "different":
            print(
                f"different  {drift.path}: cmux.json {show(drift.file)}, "
                f"Settings {show(drift.target)}"
            )
        else:
            print(
                f"manual     {drift.path}: cmux.json {show(drift.file)}, Settings stores "
                f"{show(drift.settings)} with no known cmux.json form; edit it by hand"
            )


def check(cmux: str, verbose: bool) -> int:
    label, drifts, compared, notes = analyze(cmux)
    if verbose:
        for note in notes:
            print(note)
    if not drifts:
        print(
            f"{label}: {CMUX_JSON} matches Settings ({compared} preferences compared)"
        )
        return 0
    report(drifts)
    fixable = sum(drift.kind != "manual" for drift in drifts)
    print(
        f"{label}: {len(drifts)} of {compared} preferences drift from {CMUX_JSON}",
        end="",
    )
    print("; run `just fix-cmux-settings`" if fixable else "")
    return 1


def fix(cmux: str) -> int:
    label, drifts, compared, _ = analyze(cmux)
    status = 0
    for drift in drifts:
        if drift.kind == "manual":
            report([drift])
            status = 1
            continue
        value = json.dumps(drift.target)
        result = subprocess.run(
            [cmux, "config", "set", drift.path, value],
            capture_output=True,
            text=True,
            check=False,
        )
        reading = config_get(cmux, drift.path)
        if (
            result.returncode != 0
            or reading is None
            or not same(reading["value"], drift.target)
        ):
            print(
                f"failed     {drift.path} = {value}: {result.stderr.strip() or result.stdout.strip()}"
            )
            status = 1
            continue
        print(f"fixed      {drift.path} = {value}")
    if not drifts:
        print(
            f"{label}: {CMUX_JSON} already matches Settings ({compared} preferences compared)"
        )
    return status


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    commands = parser.add_subparsers(dest="command", required=True)
    check_parser = commands.add_parser(
        "check",
        help="report Settings preferences missing from or differing in cmux.json",
    )
    check_parser.add_argument(
        "--verbose",
        action="store_true",
        help="also list excluded and unsupported settings",
    )
    commands.add_parser("fix", help="write drifted Settings preferences into cmux.json")
    args = parser.parse_args()
    cmux = cmux_binary()
    if args.command == "check":
        return check(cmux, args.verbose)
    return fix(cmux)


if __name__ == "__main__":
    sys.exit(main())
