#!/usr/bin/env python3
"""bash_rules() renders the [approval] tables of .config/ness/policy.toml."""

from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import harness_policy

BASELINE = Path(__file__).resolve().parent / "fixtures" / "harness_policy_bash_rules.json"


class BashRulesTests(unittest.TestCase):
    def test_reads_approval_from_policy_toml(self) -> None:
        approval = harness_policy.load_approval()
        self.assertIn("rm", approval["prompt_prefix"])
        self.assertIn("sudo", approval["deny_prefix"])

    def test_omp_rules_are_ordered_deny_rm_prompt_allow(self) -> None:
        a = harness_policy.load_approval()
        denies = 2 * len(a["deny_prefix"])
        rm_asks = len(harness_policy.BASH_ASK_RM_RISKY)
        rm_allows = len(harness_policy.BASH_ALLOW_RM_TMP)
        prompts = 2 * len(a["prompt_prefix"])
        approvals = [r["approval"] for r in harness_policy.bash_rules("omp")]
        i = 0
        self.assertEqual(approvals[i : i + denies], ["deny"] * denies)
        i += denies
        # omp matches first-wins: the risky-rm prompts must precede the /tmp allows.
        self.assertEqual(approvals[i : i + rm_asks], ["prompt"] * rm_asks)
        i += rm_asks
        self.assertEqual(approvals[i : i + rm_allows], ["allow"] * rm_allows)
        i += rm_allows
        self.assertEqual(approvals[i : i + prompts], ["prompt"] * prompts)
        i += prompts
        self.assertTrue(all(x == "allow" for x in approvals[i:]))

    def test_matches_pre_change_snapshot(self) -> None:
        before = json.loads(BASELINE.read_text())
        for style in ("claude-deny", "antigravity", "opencode", "omp"):
            self.assertEqual(harness_policy.bash_rules(style), before[style], style)
        self.assertEqual(harness_policy.bash_rules("claude"), before["claude"]["rules"])
        self.assertEqual(harness_policy.OMP_APPROVAL_MODE, before["modes"]["omp_approval_mode"])


if __name__ == "__main__":
    unittest.main()
