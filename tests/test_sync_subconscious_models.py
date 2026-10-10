#!/usr/bin/env python3
"""Tests for the Subconscious pricing sync's parsing and rewriting."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "sync-subconscious-models.py"
spec = importlib.util.spec_from_file_location("sync_subconscious_models", SCRIPT)
assert spec is not None and spec.loader is not None
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

PAGE = """\
# Pricing

| Model | API model string | Cached input | Input | Output |
|---|---|---|---|---|
| GLM-5.3 Marathon | `subconscious/glm-5.3-marathon` | $0.26 | $1.40 | $4.40 |
| DeepSeek V4.1 Flash Marathon | `subconscious/deepseek-v4.1-flash-marathon` | $0.007 | $0.30 | $1.40 |

| Plan | Price | Tokens per day |
|---|---|---|
| Base | $100/month | 60M |
"""

MODELS = """\
providers:
  subconscious:
    models:
      - id: subconscious/glm-5.3-marathon
        cost: { input: 9.99, output: 4.40, cacheRead: 0.26, cacheWrite: 0 }
        contextWindow: 5000000
      - id: subconscious/deepseek-v4.1-flash-marathon
        cost: { input: 0.30, output: 1.40, cacheRead: 0.007, cacheWrite: 0 }
        contextWindow: 5000000
"""


class ParsePricesTests(unittest.TestCase):
    def test_reads_model_rows_and_ignores_the_plans_table(self) -> None:
        self.assertEqual(
            sync.parse_prices(PAGE),
            {
                "subconscious/glm-5.3-marathon": {
                    "input": "1.40",
                    "output": "4.40",
                    "cached": "0.26",
                },
                "subconscious/deepseek-v4.1-flash-marathon": {
                    "input": "0.30",
                    "output": "1.40",
                    "cached": "0.007",
                },
            },
        )

    def test_exits_when_the_table_header_changes(self) -> None:
        page = PAGE.replace("Cached input", "Cache read")
        with self.assertRaisesRegex(SystemExit, "header changed"):
            sync.parse_prices(page)

    def test_exits_when_no_rows_match(self) -> None:
        page = sync.HEADER + "\n|---|---|---|---|---|\n"
        with self.assertRaisesRegex(SystemExit, "no prices parsed"):
            sync.parse_prices(page)


class RewriteTests(unittest.TestCase):
    def setUp(self) -> None:
        self.prices = sync.parse_prices(PAGE)

    def test_fixes_a_stale_price_and_leaves_every_other_line_alone(self) -> None:
        lines = MODELS.splitlines(keepends=True)
        out, changed = sync.rewrite(lines, self.prices)
        self.assertEqual(changed, ["subconscious/glm-5.3-marathon"])
        self.assertEqual(
            "".join(out),
            MODELS.replace("input: 9.99", "input: 1.40"),
        )

    def test_reports_nothing_changed_when_prices_match(self) -> None:
        fixed = MODELS.replace("input: 9.99", "input: 1.40")
        out, changed = sync.rewrite(fixed.splitlines(keepends=True), self.prices)
        self.assertEqual(changed, [])
        self.assertEqual("".join(out), fixed)

    def test_exits_when_a_declared_model_has_no_price(self) -> None:
        del self.prices["subconscious/glm-5.3-marathon"]
        with self.assertRaises(SystemExit):
            sync.rewrite(MODELS.splitlines(keepends=True), self.prices)


if __name__ == "__main__":
    unittest.main()
