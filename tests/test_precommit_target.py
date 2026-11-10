#!/usr/bin/env python3
"""Direct unit tests for .claude/hooks/scripts/commit_target.py."""

from __future__ import annotations

import importlib.util
import os
import unittest
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location(
    "commit_target",
    Path(__file__).resolve().parent.parent
    / ".claude"
    / "hooks"
    / "scripts"
    / "commit_target.py",
)
_module = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(_module)
commit_target = _module.commit_target


class CommitTargetTests(unittest.TestCase):
    def test_literal_plain_commit(self):
        self.assertEqual(commit_target("git commit", "/base"), "/base")

    def test_absolute_c_only_returns_cwd_without_commit_tok(self):
        # `-C /tmp` alone doesn't represent a complete commit command.
        self.assertIsNone(commit_target("git -C /tmp", "/base"))

    def test_absolute_path_c_then_commit(self):
        self.assertEqual(commit_target("git -C /tmp/x commit", "/base"), "/tmp/x")

    def test_chained_relative_c_resolves_successively(self):
        self.assertEqual(
            commit_target('git -C "outer dir" -C \'inner repo\' commit', "/base"),
            "/base/outer dir/inner repo",
        )

    def test_chained_after_shell_separator(self):
        self.assertEqual(commit_target("cd /tmp && git -C rel commit", "/base"), "/base/rel")

    def test_after_semicolon_boundary(self):
        self.assertEqual(commit_target("echo one; git commit", "/base"), "/base")

    def test_prose_lookalike_rejected(self):
        self.assertIsNone(commit_target("printf git commit", "/base"))

    def test_dynamic_expansion_rejected(self):
        self.assertIsNone(commit_target('git -C "$dynamic" commit', "/base"))

    def test_backtick_expansion_rejected(self):
        self.assertIsNone(commit_target("git -C `x` commit", "/base"))

    def test_missing_c_operand_rejected(self):
        self.assertIsNone(commit_target("git -C", "/base"))

    def test_c_without_commit_rejected(self):
        self.assertIsNone(commit_target("git status", "/base"))

    def test_git_option_other_than_c_rejected(self):
        self.assertIsNone(commit_target("git --git-dir x commit", "/base"))

    def test_malformed_quote_rejected(self):
        self.assertIsNone(commit_target('git -C "unclosed commit', "/base"))


if __name__ == "__main__":
    unittest.main()
