#!/usr/bin/env python3
"""List and file open backlog items; list groups them by their ``Priority:`` line.

``just backlog`` (alias ``just bl``; recipes in .config/just/backlog.just) runs
this from the repo root, which ``Path.cwd()`` is assumed to be.
"""

from __future__ import annotations

import argparse
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

PRIORITIES = ("Urgent", "High", "Medium", "Low", "Unprioritized")
INVALID_PRIORITY = "Invalid priority"
# An item carries one ``Priority: High`` line under its H1, before the first
# ``## `` section; later text (e.g. a quoted example) is never scanned.
PRIORITY_RE = re.compile(r"^Priority: (" + "|".join(PRIORITIES) + r")$", re.MULTILINE)
SECTION_RE = re.compile(r"^## ", re.MULTILINE)


@dataclass(frozen=True)
class BacklogItem:
    slug: str
    priority_lines: tuple[str, ...]

    @property
    def priority(self) -> str:
        """The item's priority, or ``INVALID_PRIORITY`` unless exactly one line is valid."""
        if len(self.priority_lines) == 1:
            return self.priority_lines[0]
        return INVALID_PRIORITY


def _rank(priority: str) -> int:
    return PRIORITIES.index(priority) if priority in PRIORITIES else len(PRIORITIES)


def read_backlog(root: Path) -> list[BacklogItem]:
    """Every ``docs/backlog/*.md`` item under ``root``, by priority, then slug."""
    items = []
    for path in (root / "docs" / "backlog").glob("*.md"):
        header = SECTION_RE.split(path.read_text(), maxsplit=1)[0]
        items.append(BacklogItem(path.stem, tuple(PRIORITY_RE.findall(header))))
    return sorted(items, key=lambda item: (_rank(item.priority), item.slug))


def format_groups(items: list[BacklogItem]) -> str:
    """One block per non-empty priority group, invalid items last."""
    blocks = []
    for priority in (*PRIORITIES, INVALID_PRIORITY):
        slugs = [item.slug for item in items if item.priority == priority]
        if slugs:
            blocks.append(
                "\n".join([f"{priority} ({len(slugs)})", *(f"  {s}" for s in slugs)])
            )
    return "\n\n".join(blocks)


def parse_priority(text: str) -> str:
    """The ``PRIORITIES`` spelling of ``text``, matched case-insensitively."""
    for priority in PRIORITIES:
        if priority.lower() == text.lower():
            return priority
    raise ValueError(
        f"unknown priority {text!r}; expected one of: {', '.join(PRIORITIES)}"
    )


def render_list(items: list[BacklogItem], priority: str | None = None) -> str:
    """``format_groups`` of every item, or of only ``priority``'s group (``"<Priority> (0)"`` when empty)."""
    if priority is None:
        return format_groups(items)
    return (
        format_groups([item for item in items if item.priority == priority])
        or f"{priority} (0)"
    )


def new_item(root: Path, title: str, priority: str) -> Path:
    """Create ``docs/backlog/<kebab-slug>.md`` with a title, ``Priority:`` line, and empty Problem and Outcome sections; never overwrite."""
    title = title.strip()
    if "\n" in title or "\r" in title:
        raise ValueError(f"title {title!r} must be a single line")
    ascii_title = (
        unicodedata.normalize("NFKD", title).encode("ascii", "ignore").decode()
    )
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_title.lower()).strip("-")
    if not slug:
        raise ValueError(
            f"title {title!r} has no ASCII letters or digits to build a slug from"
        )
    path = root / "docs" / "backlog" / f"{slug}.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("x") as handle:
            handle.write(
                f"# {title}\n\nPriority: {priority}\n\n## Problem\n\n## Outcome\n"
            )
    except FileExistsError:
        raise FileExistsError(f"{path.relative_to(root)} already exists") from None
    return path


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="List and file open backlog items.")
    commands = parser.add_subparsers(dest="command", required=True)
    list_parser = commands.add_parser(
        "list", help="print open items grouped by priority"
    )
    list_parser.add_argument(
        "priority",
        nargs="?",
        help=f"print only this priority's group: one of {', '.join(PRIORITIES)}"
        f" (case-insensitive). Items under {INVALID_PRIORITY!r} appear only in the"
        " unfiltered list.",
    )
    new_parser = commands.add_parser(
        "new", help="create docs/backlog/<slug>.md from a title"
    )
    new_parser.add_argument("title")
    new_parser.add_argument("priority", nargs="?", default="Unprioritized")
    args = parser.parse_args(argv)
    root = Path.cwd()
    try:
        if args.command == "list":
            priority = parse_priority(args.priority) if args.priority else None
            print(render_list(read_backlog(root), priority))
        else:
            priority = parse_priority(args.priority or "Unprioritized")
            print(new_item(root, args.title, priority).relative_to(root))
    except (ValueError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
