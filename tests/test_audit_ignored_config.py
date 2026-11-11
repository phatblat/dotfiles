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
TRUST = next(rx for name, rx in audit.SECRET_CONTENT if name == "trust grant")

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


class TrustGrantTests(unittest.TestCase):
    def test_codex_project_trust_is_flagged(self) -> None:
        self.assertIsNotNone(TRUST.search('[projects."/a"]\ntrust_level = "trusted"\n'))

    def test_untrusted_project_is_not_flagged(self) -> None:
        self.assertIsNone(TRUST.search('[projects."/a"]\ntrust_level = "untrusted"\n'))


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

    def test_browser_profiles_are_skipped(self) -> None:
        self.write_home(".omp/browser-profiles/google-chrome-1/manifest.json", "{}\n")
        self.assertEqual(self.scan(), [])

    def test_home_file_that_also_exists_in_the_checkout_is_skipped(self) -> None:
        (self.repo / ".omp/agent").mkdir(parents=True)
        (self.repo / ".omp/agent/config.yml").write_text("k: v\n")
        self.write_home(".omp/agent/config.yml", "k: v\n")
        self.assertEqual(self.scan(), [])

    def test_installed_mcp_config_is_state(self) -> None:
        self.write_home(".gemini/config/mcp_config.json", '{"mcpServers": {}}\n')
        (record,) = self.scan()
        self.assertEqual(record["kind"], "state")

    def test_home_config_with_credential_is_review(self) -> None:
        body = '{"' + "pass" + "word" + '": "' + HEX_VALUE + '"}\n'
        self.write_home(".omp/agent/svc.json", body)
        (record,) = self.scan()
        self.assertEqual(record["kind"], "review")

class NewStateCategoryTests(unittest.TestCase):
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
        return audit.scan_home(
            self.repo, self.home, (".claude", ".omp", ".gemini"), tracked or set()
        )

    def test_state_dirs_and_state_names_scan_to_state(self) -> None:
        # STATE_DIRS entries are pruned in scan_home's os.walk itself, so those
        # directories produce no records at all — invisible files.
        for rel in (
            ".claude/MEMORY/auto-end.md",
            ".claude/hud/banner.json",
            ".claude/powerline/theme.json",
            ".claude/shell-snapshots/a.sh",
            ".claude/browser-relay/links.json",
        ):
            self.write_home(rel)
        self.assertEqual(self.scan(), [])

    def test_state_names_scan_to_state_when_reachable(self) -> None:
        # Named state files under an otherwise config-shaped tree ARE returned
        # by scan_home, and classify() marks them state.
        self.write_home(".omp/agent/models-store.json")
        records = self.scan()
        self.assertEqual([record["kind"] for record in records], ["state"])
        self.assertEqual(
            [record["path"] for record in records],
            [".omp/agent/models-store.json"],
        )

    def test_installed_claude_files_are_state(self) -> None:
        for rel in (
            ".claude/plugins/blocklist.json",
            ".claude/plugins/installed_plugins.json",
            ".claude/policy-limits.json",
            ".claude/remote-settings.json",
        ):
            self.write_home(rel, "{}\n")
        self.assertEqual(
            {record["path"]: record["kind"] for record in self.scan()},
            {
                ".claude/plugins/blocklist.json": "state",
                ".claude/plugins/installed_plugins.json": "state",
                ".claude/policy-limits.json": "state",
                ".claude/remote-settings.json": "state",
            },
        )

    def test_security_warning_state_shape_is_state(self) -> None:
        self.write_home(".claude/security_warnings_state_02a1-f3.json", "{}\n")
        self.assertEqual(
            audit.classify(".claude/security_warnings_state_02a1-f3.json"), "state"
        )


if __name__ == "__main__":
    unittest.main()
