#!/usr/bin/env python3
"""Aggregate report for the dotfiles agent flywheel (docs/flywheel.md).

Joins the Record-stage ledgers under $XDG_STATE_HOME/flywheel/dotfiles/
(outcomes.jsonl, scaffolds.jsonl) with `harness-sessions.py --json` usage and
friction aggregates, and prints the markdown the Learn, Prune, and Tune stages
read: Record coverage, per-session outcomes, scaffold firings, and friction.

Output is counts and dates only: no task labels, session IDs, prompts, or
transcript text.

Usage:
    flywheel-report.py [--since DAYS]

Copyright: Ben Chatelain. MIT
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from collections.abc import Iterable
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

SCRIPTS = Path(__file__).resolve().parent
# Worst first: a session that failed once is a failed session.
SEVERITY = ("failed", "abandoned", "partial", "success")
# Firing signals derived from session scans rather than the scaffold ledger.
SESSION_SIGNALS = {("omp", "omp-cd-prefix")}


def state_dir() -> Path:
    xdg = os.environ.get("XDG_STATE_HOME")
    base = Path(xdg).expanduser() if xdg else Path.home() / ".local" / "state"
    return base / "flywheel" / "dotfiles"


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def collapse_outcomes(records: Iterable[dict[str, Any]]) -> dict[tuple[str, str], dict[str, Any]]:
    """One outcome per (harness, session): the worst recorded, corrected if any record is."""
    sessions: dict[tuple[str, str], dict[str, Any]] = {}
    for record in records:
        outcome = record.get("outcome")
        if outcome not in SEVERITY:
            continue
        key = (str(record.get("harness", "")), str(record.get("session_id", "")))
        current = sessions.get(key)
        if current is None:
            sessions[key] = {"outcome": outcome, "corrected": bool(record.get("corrected"))}
            continue
        if SEVERITY.index(outcome) < SEVERITY.index(current["outcome"]):
            current["outcome"] = outcome
        current["corrected"] = current["corrected"] or bool(record.get("corrected"))
    return sessions


def harness_sessions(since: int) -> dict[str, Any]:
    result = subprocess.run(
        [sys.executable, str(SCRIPTS / "harness-sessions.py"), "--since", str(since), "--json"],
        capture_output=True,
        text=True,
        check=False,
    )
    return json.loads(result.stdout)


def render(since: int, outcomes: list[dict[str, Any]], firings: list[dict[str, Any]], scan: dict[str, Any]) -> str:
    cutoff_date = (datetime.now(UTC) - timedelta(days=since)).strftime("%Y-%m-%d")
    cutoff_ts = cutoff_date + "T00:00:00"
    in_window = [r for r in outcomes if str(r.get("date", "")) >= cutoff_date]
    sessions = collapse_outcomes(in_window)
    coverage = scan.get("coverage", [])
    harnesses = [c["harness"] for c in coverage]

    lines = [f"# Flywheel report (last {since}d, since {cutoff_date})", "", "## Record coverage", ""]
    lines += ["| Harness | Session files in window | Newest session | Outcome sessions |", "|---|---|---|---|"]
    covered = 0
    for c in coverage:
        recorded = sum(1 for harness, _ in sessions if harness == c["harness"])
        if c.get("files_parsed") and recorded:
            covered += 1
        lines.append(
            f"| {c['harness']} | {c.get('files_parsed', 0)} | {(c.get('latest') or '-')[:10]} | {recorded} |"
        )
    lines += ["", f"Coverage: {covered}/{len(harnesses)} harnesses with session files and outcome records.", ""]

    lines += ["## Outcomes (worst per session)", ""]
    lines += ["| Harness | Sessions | " + " | ".join(SEVERITY) + " | Corrected |", "|---|---|---|---|---|---|---|"]
    for harness in sorted({h for h, _ in sessions}):
        rows = [s for (h, _), s in sessions.items() if h == harness]
        counts = [sum(1 for s in rows if s["outcome"] == o) for o in SEVERITY]
        corrected = sum(1 for s in rows if s["corrected"])
        lines.append(f"| {harness} | {len(rows)} | " + " | ".join(map(str, counts)) + f" | {corrected}/{len(rows)} |")
    if not sessions:
        lines.append("| - | 0 | 0 | 0 | 0 | 0 | 0/0 |")
    lines.append("")

    fired: dict[tuple[str, str], list[str]] = {}
    for f in firings:
        ts = str(f.get("ts", ""))
        if ts >= cutoff_ts:
            fired.setdefault((str(f.get("harness", "")), str(f.get("scaffold", ""))), []).append(ts)
    for row in scan.get("usage", []):
        key = (row["harness"], row["name"])
        if row["kind"] == "scaffold_signal" and key in SESSION_SIGNALS:
            fired.setdefault(key, []).extend([row["last_seen"]] * row["attempts"])
    lines += ["## Scaffold firings", "", "| Harness | Scaffold | Firings | Last fired |", "|---|---|---|---|"]
    for (harness, scaffold), stamps in sorted(fired.items()):
        lines.append(f"| {harness} | {scaffold} | {len(stamps)} | {max(stamps)[:10]} |")
    if not fired:
        lines.append("| - | - | 0 | - |")
    lines += ["", "Scaffolds absent from this table have no recorded firing in the window.", ""]

    friction = scan.get("friction", {})
    lines += ["## Friction", "", "| Harness | Tool | Class | Count |", "|---|---|---|---|"]
    for row in friction.get("error_classes", [])[:15]:
        lines.append(f"| {row['harness']} | {row['name']} | {row['class']} | {row['count']} |")
    guard = sum(r["count"] for r in friction.get("error_classes", []) if r["class"] == "guard")
    aborted = friction.get("aborted_turns", {})
    lines += [
        "",
        f"- Guard denials: {guard}",
        f"- Aborted turns: {aborted.get('count', 0)} {json.dumps(aborted.get('by_harness', {}), sort_keys=True)}",
        f"- Cache-miss reasons: {json.dumps(friction.get('cache_miss_reasons', {}), sort_keys=True)}",
        "",
    ]
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Aggregate flywheel report (Learn/Prune/Tune input).")
    parser.add_argument("--since", type=int, default=30, help="evidence window in days (default 30)")
    args = parser.parse_args(argv)
    ledgers = state_dir()
    print(
        render(
            args.since,
            read_jsonl(ledgers / "outcomes.jsonl"),
            read_jsonl(ledgers / "scaffolds.jsonl"),
            harness_sessions(args.since),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
