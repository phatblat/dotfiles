#!/usr/bin/env python3
"""Tests for Claude/Codex plugin inventory normalization."""

from __future__ import annotations

import json
from pathlib import Path
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

    @patch("agent_plugins.shutil.which", return_value=None)
    def test_audit_marks_missing_commands_unavailable(self, _which: object) -> None:
        result = audit_plugins({"claude": [], "codex": []})

        self.assertFalse(result["observed"]["claude"]["available"])
        self.assertFalse(result["observed"]["codex"]["available"])
        self.assertEqual(result["drift"], [])


if __name__ == "__main__":
    unittest.main()
