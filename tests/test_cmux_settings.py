#!/usr/bin/env python3
"""Tests for the cmux Settings-vs-cmux.json drift checker.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "cmux-settings.py"
_spec = importlib.util.spec_from_file_location("cmux_settings", SCRIPT)
assert _spec is not None and _spec.loader is not None
cs = importlib.util.module_from_spec(_spec)
sys.modules["cmux_settings"] = cs
_spec.loader.exec_module(cs)

MISSING = cs.MISSING


def key(path: str = "app.x", defaults_key: str = "xKey") -> cs.CatalogKey:
    return cs.CatalogKey(path, defaults_key)


def managed(kind: str, value: object) -> dict[str, object]:
    return {kind: {"_0": value}}


def run_quiet(function, *args):
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        result = function(*args)
    return result, out.getvalue(), err.getvalue()


class ExclusionTests(unittest.TestCase):
    def test_exact_path_prefix_and_suffix_are_excluded(self) -> None:
        self.assertIsNotNone(cs.exclusion_reason("automation.claudeBinaryPath"))
        self.assertIsNotNone(cs.exclusion_reason("account.team.id"))
        self.assertIsNotNone(cs.exclusion_reason("devices.pairing"))
        self.assertIsNotNone(cs.exclusion_reason("sidebar.width.remembered"))

    def test_near_misses_are_not_excluded(self) -> None:
        # Prefixes need their trailing dot; suffix rules do not match mid-path;
        # exact paths do not exclude their children's siblings.
        self.assertIsNone(cs.exclusion_reason("accounting.enabled"))
        self.assertIsNone(cs.exclusion_reason("sidebar.remembered.enabled"))
        self.assertIsNone(cs.exclusion_reason("automation.claudeBinaryPathX"))
        self.assertIsNone(cs.exclusion_reason("app.confirmQuit"))


class SameTests(unittest.TestCase):
    def test_bool_never_equals_number_or_string(self) -> None:
        self.assertFalse(cs.same(1, True))
        self.assertFalse(cs.same(True, 1))
        self.assertFalse(cs.same(0, False))
        self.assertFalse(cs.same("1", True))
        self.assertFalse(cs.same(True, False))
        self.assertTrue(cs.same(True, True))

    def test_non_bool_uses_plain_equality(self) -> None:
        self.assertTrue(cs.same(1, 1.0))
        self.assertFalse(cs.same("1", 1))
        self.assertTrue(cs.same(None, None))


class UnwrapTests(unittest.TestCase):
    def test_unwraps_boxed_and_bare_payloads(self) -> None:
        self.assertEqual(cs.unwrap(managed("bool", True)), ("bool", True))
        self.assertEqual(cs.unwrap({"nullableString": None}), ("nullableString", None))
        self.assertEqual(cs.unwrap({"int": 3}), ("int", 3))


class CompareTests(unittest.TestCase):
    def compare(self, source, value, settings, imported_entry=None):
        imported = {} if imported_entry is None else {"xKey": imported_entry}
        return cs.compare(key(), {"source": source, "value": value}, settings, imported)

    def test_value_only_in_settings_is_untracked(self) -> None:
        drift = self.compare("settings", "dark", "dark")
        self.assertEqual(drift.kind, "untracked")
        self.assertEqual(drift.target, "dark")

    def test_default_sourced_or_unimported_values_are_ignored(self) -> None:
        self.assertIsNone(self.compare("default", 1, 2, managed("int", 1)))
        # cmux.json value that cmux never imported cannot be attributed.
        self.assertIsNone(self.compare("cmux.json", 1, 2))

    def test_key_absent_from_plist_is_not_drift(self) -> None:
        self.assertIsNone(
            self.compare("cmux.json", True, MISSING, managed("bool", True))
        )

    def test_cleared_optional_value_is_drift_to_null(self) -> None:
        drift = self.compare(
            "cmux.json", "#fff", MISSING, managed("nullableString", "#fff")
        )
        self.assertEqual(
            (drift.kind, drift.target, drift.file), ("different", None, "#fff")
        )

    def test_optional_already_null_in_import_is_not_drift(self) -> None:
        self.assertIsNone(
            self.compare("cmux.json", None, MISSING, managed("nullableString", None))
        )

    def test_settings_equal_to_import_is_not_drift(self) -> None:
        self.assertIsNone(self.compare("cmux.json", "a", "a", managed("string", "a")))

    def test_explicit_settings_choice_beats_import(self) -> None:
        drift = self.compare("cmux.json", "a", "b", managed("string", "a"))
        self.assertEqual(
            (drift.kind, drift.target, drift.file), ("different", "b", "a")
        )

    def test_bool_vs_int_is_a_difference(self) -> None:
        drift = self.compare("cmux.json", 1, True, managed("int", 1))
        self.assertEqual(drift.kind, "different")
        self.assertIs(drift.target, True)

    def test_two_state_bool_encoded_differently_flips_file_value(self) -> None:
        # minimalMode: Settings stores "minimal", cmux.json holds a bool.
        drift = self.compare(
            "cmux.json", False, "minimal", managed("string", "standard")
        )
        self.assertEqual(drift.kind, "different")
        self.assertIs(drift.target, True)
        drift = self.compare(
            "cmux.json", True, "standard", managed("string", "minimal")
        )
        self.assertIs(drift.target, False)

    def test_unmappable_non_bool_difference_is_manual(self) -> None:
        drift = self.compare("cmux.json", "a", "c", managed("string", "b"))
        self.assertEqual((drift.kind, drift.settings, drift.file), ("manual", "c", "a"))
        self.assertIs(drift.target, MISSING)


class AnalyzeTests(unittest.TestCase):
    def analyze(self, catalog, preferences, readings, imported=None):
        if imported is not None:
            preferences = {
                **preferences,
                cs.IMPORTED_KEY: json.dumps(imported).encode(),
            }
        asked: list[str] = []

        def config_get(_cmux, path):
            asked.append(path)
            return readings.get(path)

        with (
            patch.object(cs, "installed_version", return_value=("1.2", "abc")),
            patch.object(
                cs,
                "load_catalog",
                return_value={entry.defaults_key: entry for entry in catalog},
            ),
            patch.object(cs, "read_preferences", return_value=preferences),
            patch.object(cs, "config_get", side_effect=config_get),
        ):
            return cs.analyze("cmux"), asked

    def test_excluded_keys_are_never_queried_or_reported(self) -> None:
        catalog = [key("devices.id", "dev"), key("app.a", "a")]
        readings = {
            "devices.id": {"source": "settings", "value": 1},
            "app.a": {"source": "settings", "value": 2},
        }
        (label, drifts, compared, notes), asked = self.analyze(
            catalog, {"dev": 1, "a": 2}, readings
        )
        self.assertEqual(label, "cmux 1.2 [abc]")
        self.assertEqual(asked, ["app.a"])
        self.assertEqual([drift.path for drift in drifts], ["app.a"])
        self.assertEqual(compared, 1)
        self.assertTrue(any("devices.id" in note for note in notes))

    def test_plist_keys_outside_catalog_are_ignored(self) -> None:
        (_, drifts, compared, _), asked = self.analyze(
            [key("app.a", "a")], {"windowFrame": "x", "a": 1}, {}
        )
        self.assertEqual((drifts, compared, asked), ([], 0, ["app.a"]))

    def test_empty_catalog_compares_nothing(self) -> None:
        (_, drifts, compared, notes), asked = self.analyze([], {"a": 1}, {})
        self.assertEqual((drifts, compared, notes, asked), ([], 0, [], []))

    def test_setting_unknown_to_installed_cmux_is_noted_not_compared(self) -> None:
        (_, drifts, compared, notes), _ = self.analyze(
            [key("app.a", "a")], {"a": 1}, {}
        )
        self.assertEqual((drifts, compared), ([], 0))
        self.assertEqual(len(notes), 1)
        self.assertIn("app.a", notes[0])

    def test_imported_only_key_is_still_considered(self) -> None:
        # Key cleared from the plist but present in cmux's import record.
        readings = {"app.a": {"source": "cmux.json", "value": "#fff"}}
        (_, drifts, compared, _), _ = self.analyze(
            [key("app.a", "a")],
            {},
            readings,
            imported={"a": managed("nullableString", "#fff")},
        )
        self.assertEqual(compared, 1)
        self.assertEqual([(d.kind, d.target) for d in drifts], [("different", None)])

    def test_missing_import_record_yields_no_cmux_json_drift(self) -> None:
        readings = {"app.a": {"source": "cmux.json", "value": 1}}
        (_, drifts, compared, _), _ = self.analyze(
            [key("app.a", "a")], {"a": 2}, readings
        )
        self.assertEqual((drifts, compared), ([], 1))


class CheckAndFixTests(unittest.TestCase):
    def analysis(self, drifts, compared=3):
        return patch.object(
            cs, "analyze", return_value=("cmux 1 [a]", drifts, compared, ["a note"])
        )

    def test_check_exits_zero_when_clean(self) -> None:
        with self.analysis([]):
            status, out, _ = run_quiet(cs.check, "cmux", False)
        self.assertEqual(status, 0)
        self.assertIn("3 preferences compared", out)
        self.assertNotIn("a note", out)

    def test_check_exits_one_on_drift_and_verbose_lists_notes(self) -> None:
        drifts = [cs.Drift("different", "app.a", "b", "a", target="b")]
        with self.analysis(drifts):
            status, out, _ = run_quiet(cs.check, "cmux", True)
        self.assertEqual(status, 1)
        self.assertIn("a note", out)
        self.assertIn("1 of 3", out)
        self.assertIn("just fix-cmux-settings", out)

    def test_check_does_not_suggest_fix_for_manual_only_drift(self) -> None:
        drifts = [cs.Drift("manual", "app.a", "c", "a")]
        with self.analysis(drifts):
            status, out, _ = run_quiet(cs.check, "cmux", False)
        self.assertEqual(status, 1)
        self.assertNotIn("just fix-cmux-settings", out)

    def fix(self, drifts, results, readings):
        calls: list[list[str]] = []
        results = iter(results)

        def run(command, **_kwargs):
            calls.append(command)
            return next(results)

        def config_get(_cmux, path):
            return readings[path]

        with (
            self.analysis(drifts),
            patch.object(cs.subprocess, "run", side_effect=run),
            patch.object(cs, "config_get", side_effect=config_get),
        ):
            status, out, _ = run_quiet(cs.fix, "cmux")
        return status, out, calls

    @staticmethod
    def completed(code=0, stderr=""):
        return subprocess.CompletedProcess([], code, stdout="", stderr=stderr)

    def test_fix_writes_json_encoded_targets_and_verifies(self) -> None:
        drifts = [
            cs.Drift("different", "app.flag", True, False, target=False),
            cs.Drift("different", "app.color", None, "#fff", target=None),
            cs.Drift("untracked", "app.name", "a b", target="a b"),
        ]
        readings = {
            "app.flag": {"value": False},
            "app.color": {"value": None},
            "app.name": {"value": "a b"},
        }
        status, out, calls = self.fix(drifts, [self.completed()] * 3, readings)
        self.assertEqual(status, 0)
        self.assertEqual(
            [call[3:] for call in calls],
            [["app.flag", "false"], ["app.color", "null"], ["app.name", '"a b"']],
        )
        self.assertEqual(out.count("fixed "), 3)

    def test_fix_fails_when_readback_does_not_match(self) -> None:
        drifts = [cs.Drift("different", "app.n", 1, 0, target=True)]
        # cmux stored the integer 1 instead of the boolean the target requires.
        status, out, _ = self.fix(drifts, [self.completed()], {"app.n": {"value": 1}})
        self.assertEqual(status, 1)
        self.assertIn("failed     app.n", out)

    def test_fix_continues_past_a_failed_write_and_reports_error(self) -> None:
        drifts = [
            cs.Drift("different", "app.a", 2, 1, target=2),
            cs.Drift("different", "app.b", 4, 3, target=4),
        ]
        readings = {"app.a": {"value": 1}, "app.b": {"value": 4}}
        status, out, calls = self.fix(
            drifts, [self.completed(1, "boom"), self.completed()], readings
        )
        self.assertEqual(status, 1)
        self.assertEqual(len(calls), 2)
        self.assertIn("boom", out)
        self.assertIn("fixed      app.b = 4", out)

    def test_fix_never_writes_manual_drift_and_returns_one(self) -> None:
        drifts = [cs.Drift("manual", "app.a", "c", "a")]
        status, out, calls = self.fix(drifts, [], {})
        self.assertEqual((status, calls), (1, []))
        self.assertIn("manual", out)

    def test_fix_with_no_drift_succeeds_without_writing(self) -> None:
        status, out, calls = self.fix([], [], {})
        self.assertEqual((status, calls), (0, []))
        self.assertIn("already matches", out)


class ParseCatalogTests(unittest.TestCase):
    def build(self, root: Path, section: str, constants: str = "") -> Path:
        sources = root / "Packages" / "macOS" / "CmuxSettings" / "Sources"
        keys = sources / "CmuxSettings" / "Keys"
        keys.mkdir(parents=True)
        (keys / "AppCatalogSection.swift").write_text(section)
        (sources / "Constants.swift").write_text(constants)
        return root

    def parse(self, section: str, constants: str = ""):
        with tempfile.TemporaryDirectory() as directory:
            src = self.build(Path(directory), section, constants)
            return run_quiet(cs.parse_catalog, src)

    def test_literals_and_constants_resolve_including_aliases(self) -> None:
        section = """
DefaultsKey<Bool>(id: "app.confirmQuit", userDefaultsKey: "confirmQuit", userFacing: true)
DefaultsKey<String>(
    id: Paths.theme,
    userDefaultsKey: Paths.themeKey,
    userFacing: true
)
"""
        constants = """
enum Paths {
    static let theme = "app.theme"
    static let themeKey = legacyKey
    static let legacyKey = "themeDefaults"
}
"""
        catalog, _, err = self.parse(section, constants)
        self.assertEqual(
            catalog,
            [
                cs.CatalogKey("app.confirmQuit", "confirmQuit"),
                cs.CatalogKey("app.theme", "themeDefaults"),
            ],
        )
        self.assertEqual(err, "")

    def test_keys_stored_in_another_suite_are_skipped(self) -> None:
        section = """
DefaultsKey<Bool>(
    id: "app.a",
    userDefaultsKey: "a",
    suite: "group.other"
)
DefaultsKey<Bool>(id: "app.b", userDefaultsKey: "b")
"""
        catalog, _, _ = self.parse(section)
        self.assertEqual(catalog, [cs.CatalogKey("app.b", "b")])

    def test_entry_does_not_borrow_the_next_entries_defaults_key(self) -> None:
        section = """
DefaultsKey<Bool>(id: "app.a", userFacing: true)
DefaultsKey<Bool>(id: "app.b", userDefaultsKey: "b")
"""
        catalog, _, err = self.parse(section)
        self.assertEqual(catalog, [cs.CatalogKey("app.b", "b")])
        self.assertIn("1 catalog settings", err)

    def test_userfacing_metadata_does_not_leak_into_defaults_key(self) -> None:
        section = """
DefaultsKey<Bool>(id: "app.a", userFacing: true, userDefaultsKey: "late")
"""
        with self.assertRaises(SystemExit) as raised:
            self.parse(section)
        self.assertEqual(raised.exception.code, 2)

    def test_empty_catalog_is_a_fatal_layout_change(self) -> None:
        with self.assertRaises(SystemExit) as raised:
            self.parse("// nothing here\n")
        self.assertEqual(raised.exception.code, 2)


class LoadCatalogTests(unittest.TestCase):
    def test_cache_hit_avoids_git_and_indexes_by_defaults_key(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory) / "cmux-settings"
            cache.mkdir()
            name = f"catalog{cs.CATALOG_FORMAT}-1.2-abc.json"
            (cache / name).write_text(
                json.dumps([{"path": "app.a", "defaults_key": "aKey"}])
            )
            with (
                patch.dict(os.environ, {"XDG_CACHE_HOME": directory}),
                patch.object(cs.subprocess, "run", side_effect=AssertionError),
            ):
                catalog = cs.load_catalog("1.2", "abc")
        self.assertEqual(catalog, {"aKey": cs.CatalogKey("app.a", "aKey")})

    def test_tag_built_from_a_different_commit_is_refused_and_not_cached(self) -> None:
        def run(command, **_kwargs):
            stdout = "ffffffff00\n" if "rev-parse" in command else ""
            return subprocess.CompletedProcess(command, 0, stdout=stdout, stderr="")

        with tempfile.TemporaryDirectory() as directory:
            with (
                patch.dict(os.environ, {"XDG_CACHE_HOME": directory}),
                patch.object(cs.subprocess, "run", side_effect=run),
                self.assertRaises(SystemExit) as raised,
            ):
                run_quiet(cs.load_catalog, "1.2", "abc1234")
            self.assertEqual(raised.exception.code, 2)
            self.assertEqual(list(Path(directory).rglob("*.json")), [])

    def test_matching_short_sha_parses_and_writes_cache(self) -> None:
        def run(command, **_kwargs):
            stdout = "abc1234999\n" if "rev-parse" in command else ""
            return subprocess.CompletedProcess(command, 0, stdout=stdout, stderr="")

        parsed = [cs.CatalogKey("app.a", "aKey")]
        with tempfile.TemporaryDirectory() as directory:
            with (
                patch.dict(os.environ, {"XDG_CACHE_HOME": directory}),
                patch.object(cs.subprocess, "run", side_effect=run),
                patch.object(cs, "parse_catalog", return_value=parsed),
            ):
                catalog, _, _ = run_quiet(cs.load_catalog, "1.2", "abc1234")
            cached = json.loads(
                next(Path(directory).rglob("catalog*.json")).read_text()
            )
        self.assertEqual(catalog, {"aKey": parsed[0]})
        self.assertEqual(cached, [{"path": "app.a", "defaults_key": "aKey"}])

    def test_unusable_cache_is_a_miss_that_is_refetched_and_replaced(self) -> None:
        def run(command, **_kwargs):
            stdout = "abc1234999\n" if "rev-parse" in command else ""
            return subprocess.CompletedProcess(command, 0, stdout=stdout, stderr="")

        parsed = [cs.CatalogKey("app.a", "aKey")]
        bad_caches = {
            "truncated": '[{"path": "app.a", "defaults_',
            "wrong shape": '{"path": "app.a"}',
            "missing field": '[{"path": "app.a"}]',
            "not a list of objects": "[1, 2]",
            "empty file": "",
        }
        for label, text in bad_caches.items():
            with self.subTest(label), tempfile.TemporaryDirectory() as directory:
                name = f"catalog{cs.CATALOG_FORMAT}-1.2-abc1234.json"
                cache = Path(directory) / "cmux-settings" / name
                cache.parent.mkdir()
                cache.write_text(text)
                with (
                    patch.dict(os.environ, {"XDG_CACHE_HOME": directory}),
                    patch.object(cs.subprocess, "run", side_effect=run),
                    patch.object(cs, "parse_catalog", return_value=parsed),
                ):
                    catalog, _, _ = run_quiet(cs.load_catalog, "1.2", "abc1234")
                self.assertEqual(catalog, {"aKey": parsed[0]})
                self.assertEqual(
                    json.loads(cache.read_text()),
                    [{"path": "app.a", "defaults_key": "aKey"}],
                )

    def test_interrupted_cache_write_keeps_the_old_file_and_leaves_no_temp(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            cache = Path(directory) / "cmux-settings" / "catalog.json"
            cache.parent.mkdir()
            cache.write_text("old contents")
            with (
                patch.object(cs.os, "replace", side_effect=KeyboardInterrupt),
                self.assertRaises(KeyboardInterrupt),
            ):
                cs.write_catalog_cache(cache, [cs.CatalogKey("app.a", "aKey")])
            self.assertEqual(cache.read_text(), "old contents")
            self.assertEqual([p.name for p in cache.parent.iterdir()], [cache.name])


class InstalledVersionTests(unittest.TestCase):
    def version(self, output: str):
        done = subprocess.CompletedProcess([], 0, stdout=output, stderr="")
        with patch.object(cs.subprocess, "run", return_value=done):
            return cs.installed_version("cmux")

    def test_parses_version_and_sha(self) -> None:
        self.assertEqual(
            self.version("cmux 0.63.1 (42) [deadbeef]\n"), ("0.63.1", "deadbeef")
        )

    def test_unrecognized_output_is_fatal(self) -> None:
        with self.assertRaises(SystemExit) as raised:
            run_quiet(self.version, "something else")
        self.assertEqual(raised.exception.code, 2)


class ConfigGetTests(unittest.TestCase):
    def config_get(self, code: int, stdout: str = "", stderr: str = ""):
        done = subprocess.CompletedProcess([], code, stdout=stdout, stderr=stderr)
        with patch.object(cs.subprocess, "run", return_value=done):
            return cs.config_get("cmux", "app.a")

    def test_unknown_setting_is_none(self) -> None:
        self.assertIsNone(self.config_get(1, stderr="app.a isn't a cmux setting"))

    def test_other_failure_is_fatal(self) -> None:
        with self.assertRaises(SystemExit) as raised:
            run_quiet(self.config_get, 1, "", "permission denied")
        self.assertEqual(raised.exception.code, 2)

    def test_success_parses_json(self) -> None:
        reading = self.config_get(0, '{"source": "settings", "value": 1}')
        self.assertEqual(reading, {"source": "settings", "value": 1})


if __name__ == "__main__":
    unittest.main()
