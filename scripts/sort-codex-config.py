#!/usr/bin/env python3
"""Smart-sort a Codex ``config.toml`` for readability and low diff churn.

Codex uses a lenient TOML dialect (e.g. multi-line inline tables) that strict
parsers reject, so this sorter is deliberately *text-based*: it reorders whole
lines and never re-serializes values. That keeps every value byte-for-byte
identical (the ``[otel]`` inline table, the ``notify`` array) and guarantees the
sorted file is semantically identical to the input.

Policy
------
* Bare top-level keys (e.g. ``model``) are sorted alphabetically and kept first.
* Tables are split into two groups, each ordered alphabetically by dotted path
  (parents before children):
    1. hand-authored config (everything else)
    2. machine-managed state, clustered at the bottom under a banner
       (``projects``, ``notice``, ``marketplaces``, ``plugins``, ``hooks``).
* Keys inside every table/section are sorted alphabetically.

Comments
--------
Standalone ``#`` comment lines are owned by this script: the top and state
banners are regenerated on every run, so output is idempotent. Any *other*
standalone comment line is dropped. To attach a durable note to a key, use a
*trailing* inline comment (``key = value  # related: other_key``) — those ride
along with the key line.

Usage
-----
    sort-codex-config.py <file>            # rewrite in place
    sort-codex-config.py --check <file>    # exit 1 if not already sorted
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

# Top-level tables Codex writes/owns; clustered at the bottom of the file.
STATE_TABLES: frozenset[str] = frozenset(
    {"projects", "notice", "marketplaces", "plugins", "hooks"}
)

# A table header line, e.g. `[tui.model_availability_nux]`. Headers live at
# column 0; multi-line value continuations (`]`, `} }`, indented lines) do not.
HEADER_RE = re.compile(r"^\[(?P<path>.+)\]\s*$")
# A `key = ...` line at column 0 (bare or quoted key). Continuation lines of a
# multi-line value are indented or start with `]`/`}`, so they never match.
KEY_RE = re.compile(r"^(?P<key>[^\s#=\[][^=]*?)\s*=")

_TOP_BANNER: tuple[str, ...] = (
    "Codex config.toml — hand-authored settings first, machine-managed state last.",
    "Sections/keys are alphabetized by `just format-toml`"
    " (~/scripts/sort-codex-config.py).",
    "Volatile churn (timestamps/revisions/hashes) is masked out of git by"
    " ~/scripts/mask-codex-state.sh (clean filter; see .gitattributes).",
)
_STATE_BANNER: tuple[str, ...] = (
    "─" * 74,
    "machine-managed state — written by Codex, not hand-edited.",
    "Left tracked for cross-machine parity; Codex regenerates it if removed.",
    "─" * 74,
)


def _split_dotted(path: str) -> tuple[str, ...]:
    """Split a dotted table path into components, respecting quoted segments."""
    parts: list[str] = []
    buf: list[str] = []
    quote: str | None = None
    for ch in path:
        if quote:
            if ch == quote:
                quote = None
            else:
                buf.append(ch)
        elif ch in ('"', "'"):
            quote = ch
        elif ch == ".":
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    parts.append("".join(buf))
    return tuple(parts)


def _sort_records(body: list[str]) -> list[str]:
    """Sort ``key = value`` records within a section body, keys ascending.

    A record is a key line plus any following continuation lines (multi-line
    arrays/inline tables). Blank lines and standalone comments are discarded
    (comments are handled at the document level)."""
    records: list[list[str]] = []
    current: list[str] | None = None
    for line in body:
        if KEY_RE.match(line):
            if current is not None:
                records.append(current)
            current = [line]
        elif current is not None:
            current.append(line)
        # else: leading blank/comment before any key — drop it

    if current is not None:
        records.append(current)

    def record_key(record: list[str]) -> str:
        match = KEY_RE.match(record[0])
        return match.group("key").strip().lower() if match else ""

    records.sort(key=record_key)

    out: list[str] = []
    for record in records:
        while record and not record[-1].strip():
            record.pop()
        out.extend(record)
    return out


def sort_document(text: str) -> str:
    # Drop standalone comment lines; this script owns the banners it regenerates.
    lines = [ln for ln in text.split("\n") if not ln.lstrip().startswith("#")]

    index = 0
    total = len(lines)
    preamble: list[str] = []
    while index < total and not HEADER_RE.match(lines[index]):
        preamble.append(lines[index])
        index += 1

    blocks: list[tuple[str, list[str]]] = []
    header: str | None = None
    body: list[str] = []
    while index < total:
        line = lines[index]
        if HEADER_RE.match(line):
            if header is not None:
                blocks.append((header, body))
            header, body = line, []
        else:
            body.append(line)
        index += 1
    if header is not None:
        blocks.append((header, body))

    config: list[tuple[tuple[str, ...], str, list[str]]] = []
    state: list[tuple[tuple[str, ...], str, list[str]]] = []
    for head, raw_body in blocks:
        path = _split_dotted(HEADER_RE.match(head).group("path"))
        entry = (tuple(p.lower() for p in path), head, _sort_records(raw_body))
        (state if path[0] in STATE_TABLES else config).append(entry)

    config.sort(key=lambda e: e[0])
    state.sort(key=lambda e: e[0])

    out: list[str] = [f"# {line}" for line in _TOP_BANNER]
    out.append("")
    out.extend(_sort_records(preamble))
    for _, head, sorted_body in config:
        out.append("")
        out.append(head)
        out.extend(sorted_body)
    if state:
        out.append("")
        out.extend(f"# {line}" for line in _STATE_BANNER)
        for _, head, sorted_body in state:
            out.append("")
            out.append(head)
            out.extend(sorted_body)

    return "\n".join(out).rstrip("\n") + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path, help="path to config.toml")
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero if the file is not already sorted (no write)",
    )
    args = parser.parse_args()

    original = args.file.read_text()
    formatted = sort_document(original)

    if args.check:
        if original != formatted:
            print(f"{args.file} is not sorted (run: just format-toml)", file=sys.stderr)
            return 1
        return 0

    if original != formatted:
        args.file.write_text(formatted)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
