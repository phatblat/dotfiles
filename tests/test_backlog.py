#!/usr/bin/env python3
"""Tests for scripts/backlog.py: priority parsing, slugging and the new-item guard.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "backlog.py"
_spec = importlib.util.spec_from_file_location("backlog", SCRIPT)
assert _spec is not None and _spec.loader is not None
bl = importlib.util.module_from_spec(_spec)
sys.modules["backlog"] = bl
_spec.loader.exec_module(bl)


class BacklogRoot(unittest.TestCase):
    """A temporary repo root holding an empty ``docs/backlog/``."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.root = Path(tmp.name)
        (self.root / "docs" / "backlog").mkdir(parents=True)

    def write(self, slug: str, text: str, newline: str | None = "\n") -> None:
        with (self.root / "docs" / "backlog" / f"{slug}.md").open(
            "w", newline=newline
        ) as handle:
            handle.write(text)

    def priorities(self) -> dict[str, str]:
        return {item.slug: item.priority for item in bl.read_backlog(self.root)}


class PriorityReadingTests(BacklogRoot):
    def test_priority_line_under_the_title_is_read(self) -> None:
        self.write("a", "# A\n\nPriority: High\n\n## Problem\n")
        self.assertEqual(self.priorities(), {"a": "High"})

    def test_missing_priority_line_is_invalid(self) -> None:
        self.write("a", "# A\n\n## Problem\n")
        self.assertEqual(self.priorities(), {"a": bl.INVALID_PRIORITY})

    def test_duplicate_priority_lines_are_invalid(self) -> None:
        self.write("a", "# A\n\nPriority: High\nPriority: Low\n\n## Problem\n")
        self.assertEqual(self.priorities(), {"a": bl.INVALID_PRIORITY})

    def test_unknown_priority_value_is_invalid(self) -> None:
        self.write("a", "# A\n\nPriority: Soonish\n\n## Problem\n")
        self.assertEqual(self.priorities(), {"a": bl.INVALID_PRIORITY})

    def test_priority_line_quoted_in_a_section_is_ignored(self) -> None:
        self.write(
            "a",
            "# A\n\nPriority: High\n\n## Problem\n\n```\nPriority: Low\n```\n",
        )
        self.assertEqual(self.priorities(), {"a": "High"})

    def test_priority_line_only_in_a_section_is_invalid(self) -> None:
        self.write("a", "# A\n\n## Problem\n\nPriority: High\n")
        self.assertEqual(self.priorities(), {"a": bl.INVALID_PRIORITY})

    def test_crlf_files_are_read(self) -> None:
        self.write("a", "# A\r\n\r\nPriority: High\r\n\r\n## Problem\r\n", newline="")
        self.assertEqual(self.priorities(), {"a": "High"})

    def test_items_sort_by_priority_rank_then_slug(self) -> None:
        self.write("z-urgent", "# Z\n\nPriority: Urgent\n")
        self.write("b-low", "# B\n\nPriority: Low\n")
        self.write("a-low", "# A\n\nPriority: Low\n")
        self.write("bad", "# Bad\n")
        self.assertEqual(
            [item.slug for item in bl.read_backlog(self.root)],
            ["z-urgent", "a-low", "b-low", "bad"],
        )


class RenderTests(BacklogRoot):
    def test_groups_are_counted_and_invalid_items_come_last(self) -> None:
        self.write("a", "# A\n\nPriority: Low\n")
        self.write("b", "# B\n")
        self.assertEqual(
            bl.render_list(bl.read_backlog(self.root)),
            "Low (1)\n  a\n\nInvalid priority (1)\n  b",
        )

    def test_empty_priority_filter_prints_a_zero_count(self) -> None:
        self.write("a", "# A\n\nPriority: Low\n")
        self.assertEqual(bl.render_list(bl.read_backlog(self.root), "High"), "High (0)")


class ParsePriorityTests(unittest.TestCase):
    def test_case_is_folded_to_the_canonical_spelling(self) -> None:
        self.assertEqual(bl.parse_priority("uNpRiOrItIzEd"), "Unprioritized")

    def test_unknown_priority_lists_the_valid_ones(self) -> None:
        with self.assertRaisesRegex(ValueError, "expected one of: Urgent, High"):
            bl.parse_priority("soon")


class NewItemTests(BacklogRoot):
    def test_title_is_slugged_to_ascii_kebab_case(self) -> None:
        path = bl.new_item(self.root, "  Café über-thing!  ", "High")
        self.assertEqual(path.name, "cafe-uber-thing.md")
        self.assertEqual(
            path.read_text(),
            "# Café über-thing!\n\nPriority: High\n\n## Problem\n\n## Outcome\n",
        )

    def test_created_item_reads_back_with_its_priority(self) -> None:
        bl.new_item(self.root, "Round trip", "Medium")
        self.assertEqual(self.priorities(), {"round-trip": "Medium"})

    def test_existing_item_is_never_overwritten(self) -> None:
        self.write("taken", "# Taken\n\nPriority: Low\n")
        with self.assertRaisesRegex(FileExistsError, "already exists"):
            bl.new_item(self.root, "Taken", "High")
        self.assertEqual(self.priorities(), {"taken": "Low"})

    def test_title_without_ascii_alphanumerics_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "no ASCII letters or digits"):
            bl.new_item(self.root, "!!!", "High")

    def test_multiline_title_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "single line"):
            bl.new_item(self.root, "one\ntwo", "High")


if __name__ == "__main__":
    unittest.main()
