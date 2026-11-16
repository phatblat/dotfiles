#!/usr/bin/env python3
"""Tests for the Casper model sync's parsing and merging."""

from __future__ import annotations

import importlib.util
import unittest
from functools import partial
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "sync-casper-models.py"
spec = importlib.util.spec_from_file_location("sync_casper_models", SCRIPT)
assert spec is not None and spec.loader is not None
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

PAGE = """\
# Serverless pricing

Per-model pricing. In each **Standard** or **Priority** cell, prices are
**input / cached input / output**.

| Model | Standard | Priority |
| - | - | - |
| [Ember-1](https://app.fireworks.ai/models/fireworks/ember-1) | \\$3.00 / \\$0.30 / \\$15.00 | \\$3.75 / \\$0.375 / \\$18.75 |
| [Kimi K3](https://app.fireworks.ai/models/fireworks/kimi-k3) | \\$3.00 / \\$0.30 / \\$15.00 | \\$3.75 / \\$0.375 / \\$18.75 |
| [Kimi K3 Fast](https://app.fireworks.ai/models/fireworks/kimi-k3) | \\$4.50 / \\$0.45 / \\$22.50 | — |
| [Kimi K3.1 Pro](https://app.fireworks.ai/models/fireworks/kimi-k3p1-pro) | \\$2.00 / \\$0.20 / \\$10.00 | \\$3.00 / \\$0.30 / \\$15.00 |
| [GLM 5.3](https://app.fireworks.ai/models/fireworks/glm-5p3) | \\$1.40 / \\$0.26 / \\$4.40 | \\$1.75 / \\$0.325 / \\$5.50 |

## Embeddings

| Model | Price |
| - | - |
| [All Purpose](https://app.fireworks.ai/models/fireworks/dummy) | \\$9.99 / \\$0.99 |
"""

MODELS = """\
providers:
  casper:
    compat:
      supportsStore: false
    modelOverrides:
      # Discovered models carry zero cost; the sync owns the cost lines.
      glm-5.3:
        name: Glm 5.3
        cost: { input: 9.99, output: 4.40, cacheRead: 0.26, cacheWrite: 0 }
        # Catalog 2026-11-06: probed effort ladder; the sync may rewrite the
        # efforts line but must not touch comments or compat.
        thinking:
          mode: effort
          efforts: [minimal, low, medium]
          defaultLevel: medium
        compat:
          reasoningDisableMode: none-effort

      ember:
        name: Ember-1
        cost: { input: 3.00, output: 15.00, cacheRead: 0.30, cacheWrite: 0 }
"""

PRICES = {
    "ember-1": {"input": "3.00", "output": "15.00", "cached": "0.30"},
    "kimi-k3": {"input": "3.00", "output": "15.00", "cached": "0.30"},
    "glm-5p3": {"input": "1.40", "output": "4.40", "cached": "0.26"},
}

NAMES = {
    "ember-1": "Ember-1",
    "kimi-k3": "Kimi K3",
    "glm-5p3": "GLM 5.3",
}

CATALOG = [
    {"id": "auto", "supported_reasoning_efforts": []},
    {"id": "deepseek-v4p1-flash", "supported_reasoning_efforts": []},
    {"id": "deepseek-v4p1-flash-1017", "supported_reasoning_efforts": []},
    {"id": "dittoaicoder", "supported_reasoning_efforts": []},
    {"id": "ditto-support", "supported_reasoning_efforts": []},
    {"id": "ember-1", "supported_reasoning_efforts": []},
    {"id": "glm-5.3", "supported_reasoning_efforts": ["none", "low", "medium", "high"]},
    {"id": "kimi-k3", "supported_reasoning_efforts": []},
    {"id": "ultramarine-1-flash-us", "supported_reasoning_efforts": []},
]


class ParseFireworksPricesTests(unittest.TestCase):
    def test_keys_rows_by_link_id_and_skips_variant_rows(self) -> None:
        prices, names = sync.parse_fireworks_prices(PAGE)
        self.assertEqual(
            prices,
            {
                "ember-1": {"input": "3.00", "output": "15.00", "cached": "0.30"},
                "kimi-k3": {"input": "3.00", "output": "15.00", "cached": "0.30"},
                "kimi-k3p1-pro": {"input": "2.00", "output": "10.00", "cached": "0.20"},
                "glm-5p3": {"input": "1.40", "output": "4.40", "cached": "0.26"},
            },
        )
        self.assertEqual(names["kimi-k3"], "Kimi K3")

    def test_exits_when_the_table_header_changes(self) -> None:
        page = PAGE.replace("| Standard | Priority |", "| Standard | Rush |")
        with self.assertRaisesRegex(SystemExit, "header changed"):
            sync.parse_fireworks_prices(page)

        page = sync.HEADER + "\n| - | - | - |\n"
        with self.assertRaisesRegex(SystemExit, "no prices parsed"):
            sync.parse_fireworks_prices(page)


class PriceForTests(unittest.TestCase):
    def test_maps_to_the_fireworks_rate_normally(self) -> None:
        self.assertEqual(sync.price_for("glm-5.3", PRICES), ("1.40", "4.40", "0.26"))

    def test_exits_when_the_mapped_model_is_missing_from_the_page(self) -> None:
        prices = {k: v for k, v in PRICES.items() if k != "kimi-k3"}
        with self.assertRaisesRegex(SystemExit, "not on the pricing page"):
            sync.price_for("kimi-k3", prices)

    def test_fails_closed_for_an_unclassified_id(self) -> None:
        with self.assertRaisesRegex(SystemExit, "classify it in the script"):
            sync.price_for("some-new-model", PRICES)

    def test_excluded_models_return_none(self) -> None:
        for cid in ("deepseek-v4p1-flash", "deepseek-v4p1-flash-1017"):
            self.assertIsNone(sync.price_for(cid, PRICES))

    def test_free_models_zero_out(self) -> None:
        self.assertEqual(sync.price_for("auto", PRICES), ("0", "0", "0"))


class MergeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.prices = dict(PRICES)
        self.names = dict(NAMES)
        self.executor = partial(sync.merge, prices=self.prices, names=self.names)

    def test_rewrites_cost_and_effort_lines_only(self) -> None:
        out, _changed = self.executor(MODELS.splitlines(keepends=True), CATALOG)
        text = "".join(out)
        self.assertIn("input: 1.40", text)
        self.assertNotIn("9.99", text)
        self.assertIn("efforts: [low, medium, high]", text)
        # everything else byte-identical
        self.assertIn("# Catalog 2026-11-06: probed effort ladder", text)
        self.assertIn("reasoningDisableMode: none-effort", text)
        self.assertIn("supportsStore: false", text)

    def test_removes_stale_blocks_and_skips_excluded_ids(self) -> None:
        out, changed = self.executor(MODELS.splitlines(keepends=True), CATALOG)
        text = "".join(out)
        self.assertNotIn("      ember:", text)
        self.assertNotIn("deepseek-v4p1-flash:", text)
        self.assertNotIn("deepseek-v4p1-flash-1017:", text)
        self.assertTrue(any(c == "ember" for c in changed))

    def test_appends_new_blocks_in_alphabetical_position(self) -> None:
        out, changed = self.executor(MODELS.splitlines(keepends=True), CATALOG)
        text = "".join(out)
        # alphabetically: auto < ditto-support < dittoaicoder < ember-1 < glm-5.3 < kimi-k3
        self.assertIn("      auto:\n        name: Auto\n", text)
        self.assertIn("      ditto-support:\n        name: Ditto Support\n", text)
        self.assertIn("      kimi-k3:\n        name: Kimi K3\n", text)
        pos_auto = text.index("      auto:")
        pos_dittoaicoder = text.index("      dittoaicoder:")
        pos_kimi = text.index("      kimi-k3:")
        self.assertLess(pos_auto, pos_dittoaicoder)
        self.assertGreater(pos_kimi, pos_dittoaicoder)
        self.assertTrue(any(c == "+kimi-k3" for c in changed))
        self.assertIn("cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }", text)


if __name__ == "__main__":
    unittest.main()
