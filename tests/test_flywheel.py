#!/usr/bin/env python3
"""Flywheel ledgers: what reaches outcomes.jsonl, and how sessions collapse to one outcome."""

from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"


def _load(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / filename)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


record = _load("flywheel_record", "flywheel-record.py")
report = _load("flywheel_report", "flywheel-report.py")


class OutcomeRecordTests(unittest.TestCase):
    def test_task_is_one_redacted_line_of_at_most_80_chars(self) -> None:
        token = "ghp_" + "a" * 36
        with tempfile.TemporaryDirectory() as tmp:
            ledger = Path(tmp) / "outcomes.jsonl"
            record.main(
                [
                    "outcome",
                    "--harness", "omp",
                    "--outcome", "failed",
                    "--task", f"fix login\nusing {token} " + "x" * 200,
                    "--ledger", str(ledger),
                ]
            )
            row = json.loads(ledger.read_text())
        self.assertNotIn(token, row["task"])
        self.assertIn("[REDACTED]", row["task"])
        self.assertNotIn("\n", row["task"])
        self.assertLessEqual(len(row["task"]), 80)
        self.assertEqual((row["outcome"], row["corrected"]), ("failed", False))

    def test_outcome_has_no_default(self) -> None:
        with self.assertRaises(SystemExit):
            record.build_parser().parse_args(["outcome", "--harness", "omp"])


class CollapseOutcomeTests(unittest.TestCase):
    def test_worst_outcome_and_any_correction_win_per_session(self) -> None:
        rows = [
            {"harness": "codex", "session_id": "s1", "outcome": "success", "corrected": False},
            {"harness": "codex", "session_id": "s1", "outcome": "failed", "corrected": False},
            {"harness": "codex", "session_id": "s1", "outcome": "success", "corrected": True},
            {"harness": "omp", "session_id": "s1", "outcome": "abandoned", "corrected": False},
            {"harness": "omp", "session_id": "s2", "outcome": "bogus", "corrected": True},
        ]
        self.assertEqual(
            report.collapse_outcomes(rows),
            {
                ("codex", "s1"): {"outcome": "failed", "corrected": True},
                ("omp", "s1"): {"outcome": "abandoned", "corrected": False},
            },
        )


if __name__ == "__main__":
    unittest.main()
