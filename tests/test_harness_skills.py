#!/usr/bin/env python3
"""Tests for shared skill discovery."""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from harness_skills import (
    CLAUDE_SKILL_EXCLUSIONS,
    configure,
    discover_skills,
    is_generated_pointer,
    is_procedural_skill,
)

class DiscoverSkillsTests(unittest.TestCase):
    def _tree(self, root: Path) -> Path:
        """Build `root/repo/.agents/skills` with one real and one escaping skill."""
        skills = root / "repo" / ".agents" / "skills"
        skills.mkdir(parents=True)
        (skills / "in-repo").mkdir()
        (skills / "in-repo" / "SKILL.md").write_text("---\nname: in-repo\n---\n")
        (skills / "no-skill-file").mkdir()
        outside = root / "outside" / "external-skill"
        outside.mkdir(parents=True)
        (outside / "SKILL.md").write_text("---\nname: external-skill\n---\n")
        (skills / "external-skill").symlink_to("../../../outside/external-skill")
        return skills

    def test_out_of_repo_verdict_ignores_whether_the_target_exists(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            skills = self._tree(root)
            repo = root / "repo"

            resolving = discover_skills(skills, repo)
            (root / "outside" / "external-skill" / "SKILL.md").unlink()
            (root / "outside" / "external-skill").rmdir()
            dangling = discover_skills(skills, repo)

        self.assertEqual(resolving[0], ["in-repo"])
        self.assertEqual(
            resolving[1], {"external-skill": "../../../outside/external-skill"}
        )
        self.assertEqual(dangling, resolving)

    def test_symlink_that_stays_inside_the_repo_is_rendered(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            skills = self._tree(root)
            repo = root / "repo"
            aliased = repo / "vendor" / "aliased"
            aliased.mkdir(parents=True)
            (aliased / "SKILL.md").write_text("---\nname: aliased\n---\n")
            (skills / "aliased").symlink_to("../../vendor/aliased")

            names, external = discover_skills(skills, repo)

        self.assertEqual(names, ["aliased", "in-repo"])
        self.assertNotIn("aliased", external)

    def test_missing_source_is_empty_rather_than_an_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()

            self.assertEqual(discover_skills(root / "absent", root), ([], {}))

    def test_gitignored_target_nested_inside_root_is_excluded(self) -> None:
        """Regression: a symlink target nested under `root` but excluded by
        `root`'s own `.gitignore` (the real ~/dev/agents/* shape) must not be
        treated as in-repo merely because it sits inside root's directory tree.
        """
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            repo = root / "repo"
            skills = repo / ".agents" / "skills"
            skills.mkdir(parents=True)
            subprocess.run(
                ["git", "init", "-q", str(repo)], check=True, capture_output=True
            )
            (repo / ".gitignore").write_text("dev/*\n")
            nested = repo / "dev" / "agents" / "example-skill"
            nested.mkdir(parents=True)
            (nested / "SKILL.md").write_text("---\nname: example-skill\n---\n")
            (skills / "example-skill").symlink_to("../../dev/agents/example-skill")

            resolving = discover_skills(skills, repo)
            shutil.rmtree(repo / "dev")
            dangling = discover_skills(skills, repo)

        self.assertNotIn("example-skill", resolving[0])
        self.assertEqual(
            resolving[1],
            {"example-skill": "../../dev/agents/example-skill"},
        )
        self.assertEqual(dangling, resolving)

    def test_negated_gitignore_rule_is_not_treated_as_ignore(self) -> None:
        """A path matched by an ignore pattern and then whitelisted by a later
        negation ("!...") must be discovered as in-repo, not external.
        """
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            repo = root / "repo"
            skills = repo / ".agents" / "skills"
            skills.mkdir(parents=True)
            subprocess.run(
                ["git", "init", "-q", str(repo)], check=True, capture_output=True
            )
            (repo / ".gitignore").write_text("2ndBrain*/\n!.agents/skills/whitelisted/\n")
            whitelisted = skills / "whitelisted"
            whitelisted.mkdir(parents=True)
            (whitelisted / "SKILL.md").write_text("---\nname: whitelisted\n---\n")

            names, external = discover_skills(skills, repo)

        self.assertIn("whitelisted", names)
        self.assertNotIn("whitelisted", external)


class ProceduralPolicyTests(unittest.TestCase):
    def test_sidecar_false_marks_procedural(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            skill = Path(directory) / "proc-skill"
            (skill / "agents").mkdir(parents=True)
            (skill / "SKILL.md").write_text("---\nname: proc-skill\n---\n")
            (skill / "agents" / "openai.yaml").write_text(
                "policy:\n  allow_implicit_invocation: false\n"
            )
            configure(managed_header="x", skill_source=Path(directory))
            self.assertTrue(is_procedural_skill("proc-skill"))

    def test_missing_sidecar_is_ability(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            skill = Path(directory) / "ability-skill"
            skill.mkdir()
            (skill / "SKILL.md").write_text("---\nname: ability-skill\n---\n")
            configure(managed_header="x", skill_source=Path(directory))
            self.assertFalse(is_procedural_skill("ability-skill"))

    def test_generated_pointer_shape_round_trip(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            skill = Path(directory) / "shape-skill"
            skill.mkdir()
            (skill / "SKILL.md").write_text(
                "---\nname: shape-skill\ndescription: Body here\n---\nbody"
            )
            configure(managed_header="x", skill_source=Path(directory))
            rendered = (
                "---\nname: shape-skill\ndescription: \"Body here\"\n---\n\nx\n\n"
                "Load and follow the shared skill at `~/.agents/skills/shape-skill/SKILL.md`.\n"
            )
            self.assertTrue(is_generated_pointer(rendered, "shape-skill"))
            self.assertFalse(is_generated_pointer(rendered + "edited", "shape-skill"))


class ClaudeExclusionsTests(unittest.TestCase):
    def test_membership_exactly_expected_names(self) -> None:
        self.assertEqual(
            CLAUDE_SKILL_EXCLUSIONS,
            {
                "omp-hooks",
                "boris",
                "paseo",
                "paseo-advisor",
                "paseo-committee",
                "paseo-handoff",
                "paseo-help",
                "paseo-plugin",
            },
        )


if __name__ == "__main__":
    unittest.main()
