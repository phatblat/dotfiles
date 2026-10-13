#!/usr/bin/env python3
"""Tests for the Antigravity plugin check/lock/install script.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import argparse
import contextlib
import importlib.util
import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "agy-plugins.py"
spec = importlib.util.spec_from_file_location("agy_plugins", SCRIPT)
assert spec is not None and spec.loader is not None
agy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agy)

NS = argparse.Namespace()


def write(path: Path, text: str = "x") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)
    return path


class IsolatedTestCase(unittest.TestCase):
    """Redirect every module-level path into a temporary home."""

    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name)
        self.plugins = self.home / "plugins"
        self.config = self.home / "config.json"
        self.adapter = self.home / "adapter"
        self.lock = self.home / "lock.json"
        for name, value in {
            "HOME": self.home,
            "PLUGINS_DIR": self.plugins,
            "CONFIG_JSON": self.config,
            "ADAPTER": self.adapter,
            "LOCK": self.lock,
        }.items():
            patcher = patch.object(agy, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def run_quiet(self, func, *args):
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            return func(*args)


class TreeSha256Tests(IsolatedTestCase):
    def make(self, name: str, files: dict[str, str]) -> Path:
        root = self.home / name
        root.mkdir()
        for rel, text in files.items():
            write(root / rel, text)
        return root

    def test_identical_trees_hash_equal_regardless_of_creation_order(self) -> None:
        a = self.make("a", {"x.txt": "1", "sub/y.txt": "2"})
        b = self.make("b", {"sub/y.txt": "2", "x.txt": "1"})

        self.assertEqual(agy.tree_sha256(a), agy.tree_sha256(b))

    def test_content_change_changes_hash(self) -> None:
        a = self.make("a", {"x.txt": "1"})
        b = self.make("b", {"x.txt": "2"})

        self.assertNotEqual(agy.tree_sha256(a), agy.tree_sha256(b))

    def test_rename_with_same_content_changes_hash(self) -> None:
        a = self.make("a", {"x.txt": "1"})
        b = self.make("b", {"y.txt": "1"})

        self.assertNotEqual(agy.tree_sha256(a), agy.tree_sha256(b))

    def test_moving_file_into_subdirectory_changes_hash(self) -> None:
        a = self.make("a", {"x.txt": "1"})
        b = self.make("b", {"d/x.txt": "1"})

        self.assertNotEqual(agy.tree_sha256(a), agy.tree_sha256(b))

    def test_ds_store_is_ignored_at_any_depth(self) -> None:
        a = self.make("a", {"x.txt": "1"})
        b = self.make("b", {"x.txt": "1", ".DS_Store": "junk", "d/.DS_Store": "j"})

        self.assertEqual(agy.tree_sha256(a), agy.tree_sha256(b))

    def test_file_boundaries_are_not_ambiguous(self) -> None:
        a = self.make("a", {"ab": "c"})
        b = self.make("b", {"a": "bc"})

        self.assertNotEqual(agy.tree_sha256(a), agy.tree_sha256(b))


class SnapshotTests(IsolatedTestCase):
    def plugin(self, name: str, **files: str) -> Path:
        root = self.plugins / name
        root.mkdir(parents=True)
        for rel, text in files.items():
            write(root / rel.replace("__", "/"), text)
        return root

    def test_missing_plugins_dir_yields_empty_snapshot(self) -> None:
        self.assertEqual(agy.snapshot(), {"plugins": {}})

    def test_empty_plugins_dir_yields_empty_snapshot(self) -> None:
        self.plugins.mkdir()

        self.assertEqual(agy.snapshot(), {"plugins": {}})

    def test_plain_files_in_plugins_dir_are_not_plugins(self) -> None:
        write(self.plugins / "stray.txt")

        self.assertEqual(agy.snapshot(), {"plugins": {}})

    def test_reads_versions_and_defaults(self) -> None:
        self.plugin(
            "alpha",
            **{
                "plugin.json": json.dumps({"version": "1.2.0"}),
                "installed_version.json": json.dumps({"version": "1.1.0"}),
            },
        )

        entry = agy.snapshot()["plugins"]["alpha"]

        self.assertEqual(
            entry,
            {
                "version": "1.2.0",
                "installed_version": "1.1.0",
                "enabled": True,
                "skills": 0,
            },
        )

    def test_enabled_honors_config_false_and_defaults_true_when_absent(self) -> None:
        self.plugin("off")
        self.plugin("on")
        self.plugin("unlisted")
        write(
            self.config,
            json.dumps(
                {
                    "plugins": {
                        "off": {"enabled": False},
                        "on": {"enabled": True},
                    }
                }
            ),
        )

        plugins = agy.snapshot()["plugins"]

        self.assertFalse(plugins["off"]["enabled"])
        self.assertTrue(plugins["on"]["enabled"])
        self.assertTrue(plugins["unlisted"]["enabled"])

    def test_plugin_listed_without_enabled_key_defaults_true(self) -> None:
        self.plugin("p")
        write(self.config, json.dumps({"plugins": {"p": {}}}))

        self.assertTrue(agy.snapshot()["plugins"]["p"]["enabled"])

    def test_skill_count_includes_nested_skills_only(self) -> None:
        self.plugin(
            "p",
            **{
                "skills__a__SKILL.md": "a",
                "skills__group__b__SKILL.md": "b",
                "skills__group__b__notes.md": "not a skill",
                "other__SKILL.md": "outside skills/",
            },
        )

        self.assertEqual(agy.snapshot()["plugins"]["p"]["skills"], 2)

    def test_tree_sha256_only_for_adapter_plugin(self) -> None:
        self.plugin("other", **{"a.txt": "1"})
        self.plugin(agy.ADAPTER_PLUGIN, **{"a.txt": "1"})

        plugins = agy.snapshot()["plugins"]

        self.assertNotIn("tree_sha256", plugins["other"])
        self.assertEqual(
            plugins[agy.ADAPTER_PLUGIN]["tree_sha256"],
            agy.tree_sha256(self.plugins / agy.ADAPTER_PLUGIN),
        )

    def test_malformed_json_does_not_raise_and_falls_back(self) -> None:
        self.plugin(
            "p",
            **{"plugin.json": "{not json", "installed_version.json": ""},
        )
        write(self.config, "][")

        entry = agy.snapshot()["plugins"]["p"]

        self.assertEqual(entry["version"], "")
        self.assertEqual(entry["installed_version"], "")
        self.assertTrue(entry["enabled"])

    def test_plugins_are_sorted_by_name(self) -> None:
        for name in ("zeta", "alpha", "mid"):
            self.plugin(name)

        self.assertEqual(list(agy.snapshot()["plugins"]), ["alpha", "mid", "zeta"])


class DiffTests(unittest.TestCase):
    def test_equal_snapshots_have_no_problems(self) -> None:
        snap = {"plugins": {"a": {"version": "1", "enabled": True}}}

        self.assertEqual(agy.diff(snap, json.loads(json.dumps(snap))), [])

    def test_reports_in_lock_not_installed(self) -> None:
        problems = agy.diff({"plugins": {"a": {}}}, {"plugins": {}})

        self.assertEqual(problems, ["a: in lock, not installed"])

    def test_reports_installed_not_in_lock(self) -> None:
        problems = agy.diff({"plugins": {}}, {"plugins": {"a": {}}})

        self.assertEqual(problems, ["a: installed, not in lock"])

    def test_reports_per_key_mismatch_with_both_values(self) -> None:
        old = {"plugins": {"a": {"version": "1", "enabled": True, "skills": 2}}}
        new = {"plugins": {"a": {"version": "2", "enabled": True, "skills": 3}}}

        problems = agy.diff(old, new)

        self.assertEqual(
            problems,
            [
                "a.skills: lock=2 installed=3",
                "a.version: lock='1' installed='2'",
            ],
        )

    def test_key_present_on_only_one_side_is_a_mismatch(self) -> None:
        old = {"plugins": {"a": {"version": "1"}}}
        new = {"plugins": {"a": {"version": "1", "tree_sha256": "abc"}}}

        self.assertEqual(
            agy.diff(old, new), ["a.tree_sha256: lock=None installed='abc'"]
        )

    def test_empty_lock_against_empty_install_is_clean(self) -> None:
        self.assertEqual(agy.diff({}, {"plugins": {}}), [])

    def test_empty_lock_flags_every_installed_plugin(self) -> None:
        self.assertEqual(
            agy.diff({}, {"plugins": {"b": {}, "a": {}}}),
            ["a: installed, not in lock", "b: installed, not in lock"],
        )


class AdapterDriftTests(IsolatedTestCase):
    def test_missing_adapter_is_reported(self) -> None:
        problems = agy.adapter_drift()

        self.assertEqual(len(problems), 1)
        self.assertIn("adapter missing", problems[0])

    def test_adapter_not_installed_is_reported(self) -> None:
        write(self.adapter / "a.txt")

        problems = agy.adapter_drift()

        self.assertEqual(len(problems), 1)
        self.assertIn("adapter not installed", problems[0])

    def test_differing_content_is_reported(self) -> None:
        write(self.adapter / "a.txt", "new")
        write(self.plugins / agy.ADAPTER_PLUGIN / "a.txt", "old")

        problems = agy.adapter_drift()

        self.assertEqual(len(problems), 1)
        self.assertIn("differs", problems[0])

    def test_identical_content_has_no_drift(self) -> None:
        write(self.adapter / "a.txt", "same")
        write(self.adapter / "d" / "b.txt", "same2")
        write(self.plugins / agy.ADAPTER_PLUGIN / "a.txt", "same")
        write(self.plugins / agy.ADAPTER_PLUGIN / "d" / "b.txt", "same2")
        write(self.plugins / agy.ADAPTER_PLUGIN / ".DS_Store", "junk")

        self.assertEqual(agy.adapter_drift(), [])


class CmdCheckTests(IsolatedTestCase):
    def sync_adapter(self) -> None:
        write(self.adapter / "a.txt", "same")
        write(self.plugins / agy.ADAPTER_PLUGIN / "a.txt", "same")

    def test_clean_state_with_matching_lock_returns_0(self) -> None:
        self.sync_adapter()
        self.run_quiet(agy.cmd_lock, NS)

        self.assertEqual(self.run_quiet(agy.cmd_check, NS), 0)

    def test_missing_lock_returns_1_and_names_the_lock(self) -> None:
        self.sync_adapter()
        out = io.StringIO()

        with contextlib.redirect_stdout(out):
            code = agy.cmd_check(NS)

        self.assertEqual(code, 1)
        self.assertIn("no lock file", out.getvalue())

    def test_adapter_drift_returns_1_even_when_lock_matches(self) -> None:
        self.sync_adapter()
        self.run_quiet(agy.cmd_lock, NS)
        write(self.adapter / "a.txt", "changed")

        self.assertEqual(self.run_quiet(agy.cmd_check, NS), 1)

    def test_lock_mismatch_returns_1(self) -> None:
        self.sync_adapter()
        self.run_quiet(agy.cmd_lock, NS)
        write(self.plugins / "extra" / "plugin.json", json.dumps({"version": "1"}))

        self.assertEqual(self.run_quiet(agy.cmd_check, NS), 1)

    def test_unreadable_lock_is_treated_as_empty_not_crash(self) -> None:
        self.sync_adapter()
        write(self.lock, "{corrupt")

        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = agy.cmd_check(NS)

        self.assertEqual(code, 1)
        self.assertIn("installed, not in lock", out.getvalue())


class CmdLockTests(IsolatedTestCase):
    def populate(self) -> None:
        write(
            self.plugins / "b" / "plugin.json",
            json.dumps({"version": "2", "zeta": 1}),
        )
        write(self.plugins / "a" / "skills" / "s" / "SKILL.md")
        write(self.plugins / agy.ADAPTER_PLUGIN / "f.txt", "content")

    def test_two_runs_are_byte_identical(self) -> None:
        self.populate()

        self.assertEqual(self.run_quiet(agy.cmd_lock, NS), 0)
        first = self.lock.read_bytes()
        self.run_quiet(agy.cmd_lock, NS)

        self.assertEqual(first, self.lock.read_bytes())

    def test_output_is_sorted_newline_terminated_and_path_free(self) -> None:
        self.populate()

        self.run_quiet(agy.cmd_lock, NS)
        text = self.lock.read_text()
        data = json.loads(text)

        self.assertTrue(text.endswith("}\n"))
        self.assertFalse(text.endswith("\n\n"))
        self.assertEqual(text, json.dumps(data, indent=2, sort_keys=True) + "\n")
        self.assertEqual(data, agy.snapshot())
        self.assertNotIn(str(self.home), text)

    def test_lock_with_no_plugins_is_valid_empty_snapshot(self) -> None:
        self.run_quiet(agy.cmd_lock, NS)

        self.assertEqual(json.loads(self.lock.read_text()), {"plugins": {}})


class CmdInstallTests(IsolatedTestCase):
    def test_returns_1_without_running_when_agy_not_on_path(self) -> None:
        self.adapter.mkdir()

        with (
            patch.object(agy.shutil, "which", return_value=None),
            patch.object(agy.subprocess, "run") as run,
        ):
            code = self.run_quiet(agy.cmd_install, NS)

        self.assertEqual(code, 1)
        run.assert_not_called()

    def test_returns_1_without_running_when_adapter_missing(self) -> None:
        with (
            patch.object(agy.shutil, "which", return_value="/usr/bin/agy"),
            patch.object(agy.subprocess, "run") as run,
        ):
            code = self.run_quiet(agy.cmd_install, NS)

        self.assertEqual(code, 1)
        run.assert_not_called()

    def test_runs_agy_plugin_install_on_adapter_and_propagates_code(self) -> None:
        self.adapter.mkdir()

        for returncode in (0, 3):
            with (
                patch.object(agy.shutil, "which", return_value="/usr/bin/agy"),
                patch.object(
                    agy.subprocess, "run", return_value=MagicMock(returncode=returncode)
                ) as run,
            ):
                code = self.run_quiet(agy.cmd_install, NS)

            self.assertEqual(code, returncode)
            self.assertEqual(
                run.call_args.args[0],
                ["agy", "plugin", "install", str(self.adapter)],
            )

    def test_update_does_not_lock_when_install_fails(self) -> None:
        self.adapter.mkdir()

        with (
            patch.object(agy.shutil, "which", return_value="/usr/bin/agy"),
            patch.object(agy.subprocess, "run", return_value=MagicMock(returncode=2)),
        ):
            code = self.run_quiet(agy.cmd_update, NS)

        self.assertEqual(code, 2)
        self.assertFalse(self.lock.exists())


if __name__ == "__main__":
    unittest.main()
