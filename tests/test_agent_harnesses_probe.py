#!/usr/bin/env python3
"""Tests for `agent-harnesses.py probe`: a failed --version must not log drift."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("agent_harnesses", SCRIPTS / "agent-harnesses.py")
assert spec is not None and spec.loader is not None
ah = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ah)

SLUG = next(iter(ah.HARNESSES))
RECORDED = {"first_seen": "2026-01-01", "previous": "", "version": "1.2.3"}


class FailedProbeTests(unittest.TestCase):
    def run_probe(self, reported: str) -> tuple[dict, str]:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            versions = root / "versions.json"
            versions.write_text(json.dumps({SLUG: RECORDED}))
            drift = root / "drift.jsonl"
            with (
                mock.patch.object(ah, "VERSIONS_PATH", versions),
                mock.patch.object(ah, "OBSERVED_PATH", root / "observed.json"),
                mock.patch.object(ah, "DRIFT_PATH", drift),
                mock.patch.object(ah, "resolve_cli", return_value=SLUG),
                mock.patch.object(ah, "command_version", return_value=reported),
                mock.patch.object(ah, "run_probe", return_value={"result": "pass", "detail": ""}),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(ah.command_probe(harness=SLUG), 0)
            return json.loads(versions.read_text()), drift.read_text() if drift.exists() else ""

    def test_failed_version_keeps_recorded_version_and_logs_no_drift(self) -> None:
        versions, drift = self.run_probe("")
        self.assertEqual(versions[SLUG], RECORDED)
        self.assertNotIn("version", drift)

    def test_real_version_change_is_still_recorded(self) -> None:
        versions, drift = self.run_probe("1.2.4")
        self.assertEqual(versions[SLUG]["version"], "1.2.4")
        self.assertEqual(versions[SLUG]["previous"], "1.2.3")
        self.assertIn("1.2.4", drift)


if __name__ == "__main__":
    unittest.main()
