#!/usr/bin/env python3
"""Tests for audit-ignored-config's content rules and its $HOME scan."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("audit_ignored_config", SCRIPTS / "audit-ignored-config.py")
assert spec is not None and spec.loader is not None
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)

ASSIGNED = next(rx for name, rx in audit.SECRET_CONTENT if name == "assigned credential")

# Keys and values are joined at runtime so this file holds no `key: value`
# literal for a secret scanner to mistake for a real credential.
HEX_VALUE = "ABCDEF0123456789" + "ABCDEF"
BASE32_VALUE = "JBSWY3DPEHPK3PXP" * 2
LETTERS_VALUE = "ABCDEFGHIJKLMNOPQRSTUVWX" + "1234"


def assignment(key: str, sep: str, value: str) -> str:
    return f"{key}{sep}{value}"


class AssignedCredentialTests(unittest.TestCase):
    def test_all_caps_secrets_without_underscore_are_flagged(self) -> None:
        for line in (
            assignment("pass" + "word", ": ", HEX_VALUE),
            assignment("sec" + "ret", "=", BASE32_VALUE),
            assignment("API" + "_KEY", "=", LETTERS_VALUE),
        ):
            with self.subTest(shape=line[:6]):
                self.assertIsNotNone(ASSIGNED.search(line))

    def test_env_var_names_are_not_flagged(self) -> None:
        for line in (
            assignment("api" + "Key", ": ", "SOME_API_KEY_NAME_HERE"),
            assignment('"api' + 'Key": ', '"', 'OPENAI_API_KEY_FOR_TESTS",'),
            assignment("pass" + "word", "=", "DB_PASSWORD_FROM_VAULT\n"),
        ):
            with self.subTest(shape=line[:6]):
                self.assertIsNone(ASSIGNED.search(line))

    def test_mixed_case_literal_is_flagged(self) -> None:
        line = assignment("api" + "Key", ": ", "abcDEF0123456789" + "abcdef")
        self.assertIsNotNone(ASSIGNED.search(line))


class HomeScanTests(unittest.TestCase):
    ROOTS = (".omp", ".gemini")

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.repo = Path(tmp.name) / "repo"
        self.home = Path(tmp.name) / "home"
        self.repo.mkdir()
        self.home.mkdir()

    def write_home(self, rel: str, text: str = "content\n") -> Path:
        path = self.home / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def scan(self, tracked: set[str] | None = None) -> list[dict]:
        return audit.scan_home(self.repo, self.home, self.ROOTS, tracked or set())

    def test_home_only_config_file_is_a_candidate(self) -> None:
        self.write_home(".omp/agent/new-rule.md")
        (record,) = self.scan()
        self.assertEqual(record["kind"], "config")
        self.assertEqual(record["source"], "home")
        self.assertEqual(record["path"], ".omp/agent/new-rule.md")

    def test_links_tracked_files_and_state_dirs_are_skipped(self) -> None:
        deployed = self.repo / ".omp/agent/config.yml"
        deployed.parent.mkdir(parents=True)
        deployed.write_text("k: v\n")
        link = self.home / ".omp/agent/config.yml"
        link.parent.mkdir(parents=True)
        link.symlink_to(deployed)
        self.write_home(".omp/agent/models.yml")
        self.write_home(".omp/agent/sessions/a.json", "{}\n")
        self.assertEqual(self.scan(tracked={".omp/agent/models.yml"}), [])

    def test_installed_mcp_config_is_state(self) -> None:
        self.write_home(".gemini/config/mcp_config.json", '{"mcpServers": {}}\n')
        (record,) = self.scan()
        self.assertEqual(record["kind"], "state")

    def test_home_config_with_credential_is_review(self) -> None:
        body = '{"' + "pass" + "word" + '": "' + HEX_VALUE + '"}\n'
        self.write_home(".omp/agent/svc.json", body)
        (record,) = self.scan()
        self.assertEqual(record["kind"], "review")


if __name__ == "__main__":
    unittest.main()
