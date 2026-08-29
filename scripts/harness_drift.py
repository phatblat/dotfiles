"""Deterministic capability probes and the append-only harness drift ledger.

Copyright: Ben Chatelain. Apache 2.0.

Split out of ``scripts/agent-harnesses.py`` so these rules stay agent-editable
while the guard wiring in that module remains human-only
(``~/.agents/harness/hooks/safety.py`` lists agent-harnesses.py as control
plane, because it is the sole consumer of the safety policy).

That split only holds while this module stays off the ``guard`` fast path.
Every caller of the names defined here is reached solely from ``generate``,
``validate``, ``probe``, and ``drift``, and agent-harnesses.py imports this
module inside its non-fast-path block. So an edit here cannot influence a
safety decision.

Two ideas live here and must not be conflated:

drift
    A change in observed state over time, usually after a release, recorded one
    JSON object per line in ``docs/harness/drift.jsonl``.
``plugins.drift``
    The pre-existing configured-vs-observed plugin mismatch array produced by
    ``agent_plugins.audit_plugins()``. Unrelated, and left alone.

A probe never decides ``parity``. A file-existence check cannot prove a harness
is aligned, so probes only supply evidence and raise drift; the registry in
``harness_capabilities.py`` is never machine-rewritten.
"""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

from harness_paths import CLI_BINARIES, CONFIG_ROOTS

# Probe kinds a Cell may declare. `file_*` carry a HOME-relative `path`,
# `*_contains` carry a regex `pattern`, and `cli_*` carry a space-separated
# `args` string appended to CLI_BINARIES[slug].
PROBE_KINDS = ("file_exists", "file_contains", "cli_help_contains", "cli_exit_zero")

# Fields diff_states() compares for one cell, mapped to their ledger field name.
_CELL_FIELDS = (
    ("result", "probe"),
    ("parity", "parity"),
    ("mode", "mode"),
    ("surface", "surface"),
)

_CLI_TIMEOUT = 5


def run_probe(slug: str, probe: dict[str, str], *, home: Path) -> dict[str, str]:
    """Run one declared probe and return `{"result", "detail"}`.

    ``result`` is ``pass``, ``fail``, or ``unavailable``. ``unavailable`` is
    deliberately distinct from ``fail``: a harness that is not installed or not
    configured on this machine must never read as a regression.
    """
    kind = probe.get("kind", "")
    if kind in {"file_exists", "file_contains"}:
        return _run_file_probe(slug, probe, home=home)
    if kind in {"cli_exit_zero", "cli_help_contains"}:
        return _run_cli_probe(slug, probe)
    return {"result": "unavailable", "detail": f"unknown probe kind {kind!r}"}


def _run_file_probe(slug: str, probe: dict[str, str], *, home: Path) -> dict[str, str]:
    """Check a generated artifact exists, and optionally matches a pattern."""
    rel = probe.get("path", "")
    roots = [
        root
        for root in CONFIG_ROOTS.get(slug, ())
        if rel == root or rel.startswith(f"{root}/")
    ]
    # Only a path inside the harness's own config root can be unavailable: an
    # absent root means the harness is not configured on this machine. A shared
    # or generated adapter artifact is repo-owned and always expected, so a
    # missing one is a real failure. CONFIG_ROOTS deliberately excludes the
    # generated adapter directories, which is why this has to be per-path.
    if roots and not any((home / root).is_dir() for root in roots):
        return {
            "result": "unavailable",
            "detail": f"{slug} is not configured under {home}",
        }
    target = home / rel
    if not target.is_file():
        return {"result": "fail", "detail": f"missing {rel}"}
    if probe["kind"] == "file_exists":
        return {"result": "pass", "detail": rel}
    pattern = probe.get("pattern", "")
    if re.search(pattern, target.read_text(errors="ignore")) is None:
        return {"result": "fail", "detail": f"pattern not found in {rel}"}
    return {"result": "pass", "detail": f"{rel} matches {pattern}"}


def _run_cli_probe(slug: str, probe: dict[str, str]) -> dict[str, str]:
    """Run the harness binary; a missing binary or a timeout is unavailable."""
    binary = CLI_BINARIES.get(slug, "")
    if not binary or shutil.which(binary) is None:
        return {"result": "unavailable", "detail": f"{binary or slug} not on PATH"}
    kind = probe["kind"]
    args = ["--help"] if kind == "cli_help_contains" else probe.get("args", "").split()
    try:
        result = subprocess.run(
            [binary, *args],
            capture_output=True,
            text=True,
            check=False,
            timeout=_CLI_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return {"result": "unavailable", "detail": f"{binary}: {exc}"}
    printed = f"{binary} {' '.join(args)}".strip()
    if kind == "cli_exit_zero":
        if result.returncode == 0:
            return {"result": "pass", "detail": printed}
        return {"result": "fail", "detail": f"{printed} exited {result.returncode}"}
    pattern = probe.get("pattern", "")
    if re.search(pattern, result.stdout + result.stderr) is None:
        return {"result": "fail", "detail": f"{printed} output lacks {pattern}"}
    return {"result": "pass", "detail": f"{printed} output matches {pattern}"}


def diff_states(
    previous: dict[str, Any], current: dict[str, Any], *, date: str
) -> list[dict[str, str]]:
    """Return drift records for everything that changed between two snapshots.

    A snapshot is ``{"observed": {slug: {capability: {...}}}, "versions": {slug:
    version}}``. A key present in ``current`` but absent from ``previous``
    emits nothing: a first observation is not drift.
    """
    records: list[dict[str, str]] = []
    previous_observed = previous.get("observed", {})
    previous_versions = previous.get("versions", {})
    current_versions = current.get("versions", {})

    for slug, cells in sorted(current.get("observed", {}).items()):
        previous_cells = previous_observed.get(slug, {})
        version_from = previous_versions.get(slug, "")
        version_to = current_versions.get(slug, "")
        for capability, cell in sorted(cells.items()):
            was = previous_cells.get(capability)
            if was is None:
                continue
            for key, field in _CELL_FIELDS:
                if key not in cell and key not in was:
                    continue
                if was.get(key, "") == cell.get(key, ""):
                    continue
                records.append(
                    {
                        "date": date,
                        "harness": slug,
                        "capability": capability,
                        "field": field,
                        "from": str(was.get(key, "")),
                        "to": str(cell.get(key, "")),
                        "version_from": version_from,
                        "version_to": version_to,
                        "detail": str(cell.get("detail", "")),
                    }
                )

    for slug, version in sorted(current_versions.items()):
        if slug not in previous_versions:
            continue
        was = previous_versions[slug]
        if was == version:
            continue
        records.append(
            {
                "date": date,
                "harness": slug,
                "capability": "-",
                "field": "version",
                "from": was,
                "to": version,
                "version_from": was,
                "version_to": version,
                "detail": "",
            }
        )
    return records


def append_records(path: Path, records: list[dict[str, str]]) -> None:
    """Append drift records to the ledger, newest last. No-op when empty."""
    if not records:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        json.dumps(record, sort_keys=True, separators=(",", ":")) for record in records
    ]
    with path.open("a", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def load_records(path: Path, limit: int | None = None) -> list[dict[str, Any]]:
    """Return ledger records newest-first, at most `limit` of them."""
    if not path.exists():
        return []
    records: list[dict[str, Any]] = []
    for number, line in enumerate(path.read_text().splitlines(), start=1):
        if not line.strip():
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError as exc:
            raise ValueError(f"{path} line {number} is not valid JSON: {exc}") from exc
    records.reverse()
    return records if limit is None else records[:limit]
