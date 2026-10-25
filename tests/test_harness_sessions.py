#!/usr/bin/env python3
"""Tests for harness-sessions: usage confidence labels, Pi session roots, OMP error classes."""

from __future__ import annotations

import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("harness_sessions", SCRIPTS / "harness-sessions.py")
assert spec is not None and spec.loader is not None
hs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hs)


def _obs(kind: str, name: str, ok: bool | None) -> object:
    sink: list = []
    hs.emit(sink, harness="omp", session="s1", kind=kind, name=name, ok=ok)
    return sink[0]


def _confidence(kind: str, name: str, ok: bool | None) -> str:
    return hs.aggregate_usage([_obs(kind, name, ok)])[0]["confidence"]


class UsageConfidenceTests(unittest.TestCase):
    def test_unjoined_device_and_skill_attempts_are_not_confirmed(self) -> None:
        self.assertEqual(_confidence("device_call", "ast_grep", None), "attempt only")
        self.assertEqual(_confidence("skill_read", "brainstorm", None), "attempt only")

    def test_a_joined_result_confirms_the_call_even_when_it_failed(self) -> None:
        self.assertEqual(_confidence("tool_call", "write", False), "confirmed invocation")
        self.assertEqual(_confidence("tool_call", "write", True), "confirmed invocation")

    def test_events_without_a_result_stay_confirmed(self) -> None:
        self.assertEqual(_confidence("skill_invoke", "brainstorm", None), "confirmed invocation")


class PiSessionRootTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        patcher = mock.patch.object(hs, "HOME", self.home)
        patcher.start()
        self.addCleanup(patcher.stop)
        env = {k: v for k, v in os.environ.items() if not k.startswith("PI_")}
        env_patcher = mock.patch.dict(os.environ, env, clear=True)
        env_patcher.start()
        self.addCleanup(env_patcher.stop)

    def _store(self) -> object:
        return hs.SESSION_STORES["pi"]

    def test_session_dir_env_beats_settings_and_agent_dir(self) -> None:
        agent = self.home / "agent"
        agent.mkdir()
        (agent / "settings.json").write_text(json.dumps({"sessionDir": str(self.home / "from-settings")}))
        flat = self.home / "pi-sessions-flat"
        with mock.patch.dict(
            os.environ,
            {"PI_CODING_AGENT_DIR": str(agent), "PI_CODING_AGENT_SESSION_DIR": str(flat)},
        ):
            root, source = hs.resolve_session_root("pi", self._store())
        self.assertEqual((root, source), (flat, "env:PI_CODING_AGENT_SESSION_DIR"))

    def test_settings_session_dir_beats_agent_dir(self) -> None:
        agent = self.home / "agent"
        agent.mkdir()
        custom = self.home / "custom-transcripts"
        (agent / "settings.json").write_text(json.dumps({"sessionDir": str(custom)}))
        with mock.patch.dict(os.environ, {"PI_CODING_AGENT_DIR": str(agent)}):
            root, source = hs.resolve_session_root("pi", self._store())
        self.assertEqual((root, source), (custom, "settings:sessionDir"))

    def test_custom_session_dir_is_scanned_whatever_its_basename(self) -> None:
        flat = self.home / "pi-sessions-flat"
        flat.mkdir()
        (flat / "2026-10-18T00-00-00_abc.jsonl").write_text(
            json.dumps({"type": "session", "id": "abc", "timestamp": "2026-10-18T00:00:00Z"}) + "\n"
        )
        with mock.patch.dict(os.environ, {"PI_CODING_AGENT_SESSION_DIR": str(flat)}):
            _, coverage = hs.scan_harness("pi", since_days=365, max_files=10)
        self.assertEqual(coverage.files_seen, 1)

    def test_files_dropped_by_max_files_are_reported_as_a_gap(self) -> None:
        flat = self.home / "pi-sessions-flat"
        flat.mkdir()
        for sid in ("a", "b", "c"):
            (flat / f"2026-10-18T00-00-00_{sid}.jsonl").write_text(
                json.dumps({"type": "session", "id": sid, "timestamp": "2026-10-18T00:00:00Z"}) + "\n"
            )
        with mock.patch.dict(os.environ, {"PI_CODING_AGENT_SESSION_DIR": str(flat)}):
            _, coverage = hs.scan_harness("pi", since_days=365, max_files=2)
        self.assertEqual(coverage.files_skipped_max, 1)
        self.assertTrue(any("--max-files 2 skipped 1 of 3" in gap for gap in coverage.gaps))


class OmpErrorClassTests(unittest.TestCase):
    def test_a_blank_leading_line_does_not_hide_the_message(self) -> None:
        message = {"content": "\n\nprotected file blocked: /Users/x/.ssh/id_ed25519"}
        self.assertEqual(hs._omp_error_class(message), "guard")

class AbortAttributionTests(unittest.TestCase):
    def test_aborts_are_grouped_by_harness_before_reason(self) -> None:
        def abort(harness: str, reason: str) -> object:
            return hs.Obs(harness=harness, session="s", ts="", actor="system", kind="turn_abort", name="", ok=None, ms=None, detail=reason)
        friction = hs.aggregate_friction([], [abort("omp", "sighup"), abort("opencode", "message_error"), abort("omp", "sighup"), abort("omp", "")])
        self.assertEqual(friction["aborted_turns"], {"count": 4, "by_harness": {"omp": {"sighup": 2, "unknown": 1}, "opencode": {"message_error": 1}}})

if __name__ == "__main__":
    unittest.main()
