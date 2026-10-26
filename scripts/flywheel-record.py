#!/usr/bin/env python3
"""Append per-task outcome and scaffold-firing records for the dotfiles flywheel.

Writes only outside git, under $XDG_STATE_HOME/flywheel/dotfiles/ (default
~/.local/state/flywheel/dotfiles/):
- outcomes.jsonl: date, harness, session_id, task, outcome, corrected
- scaffolds.jsonl: ts, harness, scaffold, detail

Hooks record the end state they can observe (a failed turn, an interrupted
run, a normal end); `flywheel-report.py` keeps the worst outcome per session.
Nothing here stores prompts, transcript excerpts, or tool output: `task` and
`detail` are single-line, at most 80 characters, with secret-shaped tokens
redacted.

Copyright: Ben Chatelain. MIT
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

OUTCOMES = ("success", "partial", "failed", "abandoned")
MAX_TEXT_LEN = 80

_SECRET_RE = re.compile(
    r"(?i)(AKIA[0-9A-Z]{16}|(?<![A-Za-z0-9_-])sk-[A-Za-z0-9_-]{20,}"
    r"|ghp_[A-Za-z0-9]{36}|gho_[A-Za-z0-9]{36}|glpat-[A-Za-z0-9_-]{20,}"
    r"|xox[bpoas]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY-----)"
)
_OPAQUE_ID_RE = re.compile(r"[0-9A-Za-z-]{8,64}")


def state_dir() -> Path:
    xdg = os.environ.get("XDG_STATE_HOME")
    base = Path(xdg).expanduser() if xdg else Path.home() / ".local" / "state"
    return base / "flywheel" / "dotfiles"


def sanitize_text(text: str) -> str:
    """One line, secret-shaped tokens redacted, at most 80 characters."""
    single = " ".join(text.split())
    return _SECRET_RE.sub("[REDACTED]", single)[:MAX_TEXT_LEN]


def opaque_session_id(raw: str) -> str:
    """Harness session IDs pass through; anything else is hashed."""
    clean = raw.strip()
    if not clean:
        return "unknown"
    if _OPAQUE_ID_RE.fullmatch(clean):
        return clean
    return hashlib.sha256(clean.encode("utf-8")).hexdigest()[:12]


def append_jsonl(path: Path, record: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, sort_keys=True) + "\n")


def hook_session_id() -> str:
    """`session_id` from a hook's JSON stdin payload (Claude, Codex)."""
    if sys.stdin.isatty():
        return ""
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return ""
    return str(payload.get("session_id", "")) if isinstance(payload, dict) else ""


def cmd_outcome(args: argparse.Namespace) -> int:
    session = args.session_id or (hook_session_id() if args.from_hook_stdin else "")
    record = {
        "corrected": args.corrected,
        "date": args.date or datetime.now(UTC).strftime("%Y-%m-%d"),
        "harness": args.harness,
        "outcome": args.outcome,
        "session_id": opaque_session_id(session),
        "task": sanitize_text(args.task or f"{args.harness} session"),
    }
    ledger = Path(args.ledger).expanduser() if args.ledger else state_dir() / "outcomes.jsonl"
    append_jsonl(ledger, record)
    return 0


def cmd_scaffold(args: argparse.Namespace) -> int:
    record = {
        "detail": sanitize_text(args.detail),
        "harness": args.harness,
        "scaffold": args.scaffold,
        "ts": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    ledger = Path(args.ledger).expanduser() if args.ledger else state_dir() / "scaffolds.jsonl"
    append_jsonl(ledger, record)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Append flywheel outcome or scaffold-firing records.")
    sub = parser.add_subparsers(dest="subcommand", required=True)

    outcome = sub.add_parser("outcome", help="append one task outcome record")
    outcome.add_argument("--harness", required=True, help="harness slug (omp, claude, codex, ...)")
    outcome.add_argument("--outcome", required=True, choices=OUTCOMES)
    outcome.add_argument("--corrected", action="store_true", help="the user corrected the agent")
    outcome.add_argument("--task", default="", help="short task label (<=80 chars, no secrets)")
    outcome.add_argument("--session-id", default="", help="harness session ID")
    outcome.add_argument(
        "--from-hook-stdin",
        action="store_true",
        help="read session_id from the hook's JSON payload on stdin",
    )
    outcome.add_argument("--date", default="", help="override YYYY-MM-DD")
    outcome.add_argument("--ledger", default="", help="override outcomes.jsonl path")

    scaffold = sub.add_parser("scaffold", help="append one timestamped scaffold firing")
    scaffold.add_argument("--scaffold", required=True, help="Scaffolding register ID")
    scaffold.add_argument("--harness", required=True, help="harness slug")
    scaffold.add_argument("--detail", default="", help="bounded firing detail")
    scaffold.add_argument("--ledger", default="", help="override scaffolds.jsonl path")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.subcommand == "outcome":
        return cmd_outcome(args)
    return cmd_scaffold(args)


if __name__ == "__main__":
    raise SystemExit(main())
