#!/usr/bin/env python3
"""Tests for audit-ignored-config's assigned-credential content rule."""

from __future__ import annotations

import importlib.util
import sys
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


if __name__ == "__main__":
    unittest.main()
