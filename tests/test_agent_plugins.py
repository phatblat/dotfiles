#!/usr/bin/env python3
"""Tests for Claude/Codex plugin inventory normalization."""

from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from agent_plugins import (  # noqa: E402
    audit_plugins,
    configured_plugins,
    normalize_live_plugins,
)


class ConfiguredPluginTests(unittest.TestCase):
    def test_reads_codex_multiline_inline_table_dialect(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".codex").mkdir()
            (root / ".codex" / "config.toml").write_text(
                """
[otel]
exporter = { otlp-http = {
    endpoint = "https://otlp.example.test/v1/logs",
    protocol = "binary",
} }

[plugins."pup@datadog-pup"]
enabled = true
""".lstrip()
            )

            result = configured_plugins(root)

        self.assertEqual(result["codex"][0]["id"], "pup@datadog-pup")
        self.assertTrue(result["codex"][0]["enabled"])

    def test_normalizes_tracked_claude_and_codex_plugins(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / ".claude").mkdir()
            (root / ".codex").mkdir()
            (root / ".claude" / "settings.json").write_text(
                json.dumps(
                    {
                        "enabledPlugins": {
                            "pup@datadog-pup": True,
                            "disabled@example": False,
                        },
                        "extraKnownMarketplaces": {
                            "datadog-pup": {
                                "source": {
                                    "source": "github",
                                    "repo": "DataDog/pup",
                                }
                            }
                        },
                    }
                )
            )
            (root / ".codex" / "config.toml").write_text(
                """
[marketplaces.datadog-pup]
source_type = "git"
source = "https://github.com/DataDog/pup.git"

[plugins."pup@datadog-pup"]
enabled = true

[plugins."disabled@example"]
enabled = false
""".lstrip()
            )

            result = configured_plugins(root)

        self.assertEqual(
            result["claude"],
            [
                {
                    "id": "disabled@example",
                    "enabled": False,
                    "marketplace": "example",
                    "marketplace_source": None,
                },
                {
                    "id": "pup@datadog-pup",
                    "enabled": True,
                    "marketplace": "datadog-pup",
                    "marketplace_source": "github:DataDog/pup",
                },
            ],
        )
        self.assertEqual(result["codex"][1]["id"], "pup@datadog-pup")
        self.assertEqual(
            result["codex"][1]["marketplace_source"],
            "https://github.com/DataDog/pup.git",
        )


class LivePluginTests(unittest.TestCase):
    def test_normalizes_claude_list_schema(self) -> None:
        result = normalize_live_plugins(
            "claude",
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "0.25.0",
                    "scope": "user",
                    "enabled": False,
                }
            ],
        )
        self.assertEqual(
            result,
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "0.25.0",
                    "installed": True,
                    "enabled": False,
                    "scope": "user",
                }
            ],
        )

    def test_normalizes_codex_list_schema(self) -> None:
        result = normalize_live_plugins(
            "codex",
            {
                "installed": [
                    {
                        "pluginId": "pup@datadog-pup",
                        "version": "1.6.6",
                        "installed": True,
                        "enabled": True,
                    }
                ]
            },
        )
        self.assertEqual(
            result,
            [
                {
                    "id": "pup@datadog-pup",
                    "version": "1.6.6",
                    "installed": True,
                    "enabled": True,
                    "scope": None,
                }
            ],
        )

    @patch("agent_plugins.shutil.which", return_value="/usr/bin/harness")
    @patch("agent_plugins.subprocess.run")
    def test_audit_reports_all_plugin_drift_in_deterministic_order(
        self, run: object, _which: object
    ) -> None:
        run.side_effect = [
            subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout=json.dumps(
                    [
                        {
                            "id": "b-enabled@example",
                            "version": "1.0.0",
                            "enabled": False,
                        },
                        {
                            "id": "a-untracked@example",
                            "version": "1.0.0",
                            "enabled": True,
                        },
                    ]
                ),
                stderr="",
            ),
            subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout=json.dumps(
                    {
                        "installed": [
                            {
                                "pluginId": "installed-false@example",
                                "version": "1.0.0",
                                "installed": False,
                                "enabled": False,
                            }
                        ]
                    }
                ),
                stderr="",
            ),
        ]
        configured = {
            "claude": [
                {"id": "z-missing@example", "enabled": True},
                {"id": "b-enabled@example", "enabled": True},
            ],
            "codex": [
                {"id": "installed-false@example", "enabled": False},
            ],
        }

        result = audit_plugins(configured)

        self.assertEqual(
            result["drift"],
            [
                {
                    "harness": "claude",
                    "id": "a-untracked@example",
                    "field": "configured",
                    "configured": False,
                    "observed": True,
                },
                {
                    "harness": "claude",
                    "id": "b-enabled@example",
                    "field": "enabled",
                    "configured": True,
                    "observed": False,
                },
                {
                    "harness": "claude",
                    "id": "z-missing@example",
                    "field": "installed",
                    "configured": True,
                    "observed": False,
                },
                {
                    "harness": "codex",
                    "id": "installed-false@example",
                    "field": "installed",
                    "configured": True,
                    "observed": False,
                },
            ],
        )

    @patch("agent_plugins.shutil.which", return_value=None)
    def test_audit_marks_missing_commands_unavailable(self, _which: object) -> None:
        result = audit_plugins({"claude": [], "codex": []})

        self.assertFalse(result["observed"]["claude"]["available"])
        self.assertFalse(result["observed"]["codex"]["available"])
        self.assertEqual(result["drift"], [])

    @patch("agent_plugins.shutil.which", return_value="/usr/bin/harness")
    @patch("agent_plugins.subprocess.run")
    def test_audit_marks_nonzero_commands_unavailable(
        self, run: object, _which: object
    ) -> None:
        run.return_value = subprocess.CompletedProcess(
            args=[],
            returncode=2,
            stdout="",
            stderr="permission denied",
        )

        result = audit_plugins({"claude": [], "codex": []})

        for harness in ("claude", "codex"):
            self.assertEqual(
                result["observed"][harness],
                {
                    "available": False,
                    "plugins": [],
                    "error": "permission denied",
                },
            )
        self.assertEqual(result["drift"], [])

    @patch("agent_plugins.shutil.which", return_value="/usr/bin/harness")
    @patch("agent_plugins.subprocess.run")
    def test_audit_marks_malformed_json_unavailable(
        self, run: object, _which: object
    ) -> None:
        run.return_value = subprocess.CompletedProcess(
            args=[],
            returncode=0,
            stdout="not JSON",
            stderr="",
        )

        result = audit_plugins({"claude": [], "codex": []})

        for harness in ("claude", "codex"):
            observed = result["observed"][harness]
            self.assertFalse(observed["available"])
            self.assertEqual(observed["plugins"], [])
            self.assertIn(f"invalid {harness} plugin JSON:", observed["error"])
        self.assertEqual(result["drift"], [])

    @patch("agent_plugins.shutil.which", return_value="/usr/bin/harness")
    @patch("agent_plugins.subprocess.run")
    def test_audit_marks_invalid_decoded_schemas_unavailable(
        self, run: object, _which: object
    ) -> None:
        run.side_effect = [
            subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout="{}",
                stderr="",
            ),
            subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout='{"installed": null}',
                stderr="",
            ),
        ]

        result = audit_plugins({"claude": [], "codex": []})

        self.assertEqual(
            result["observed"]["claude"],
            {
                "available": False,
                "plugins": [],
                "error": "invalid claude plugin schema: expected a JSON array",
            },
        )
        self.assertEqual(
            result["observed"]["codex"],
            {
                "available": False,
                "plugins": [],
                "error": (
                    "invalid codex plugin schema: expected an object with an "
                    "'installed' array"
                ),
            },
        )
        self.assertEqual(result["drift"], [])

    @patch("agent_plugins.shutil.which", return_value="/usr/bin/harness")
    @patch("agent_plugins.subprocess.run", side_effect=OSError("launch failed"))
    def test_audit_marks_launch_exceptions_unavailable(
        self, _run: object, _which: object
    ) -> None:
        result = audit_plugins({"claude": [], "codex": []})

        for harness in ("claude", "codex"):
            self.assertEqual(
                result["observed"][harness],
                {
                    "available": False,
                    "plugins": [],
                    "error": f"{harness} plugin list failed: launch failed",
                },
            )
        self.assertEqual(result["drift"], [])


if __name__ == "__main__":
    unittest.main()
