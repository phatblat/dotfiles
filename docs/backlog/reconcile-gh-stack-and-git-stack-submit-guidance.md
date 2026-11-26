# Reconcile gh-stack and git-stack submit guidance

Priority: Medium

## Problem

The 2026-11-26 audit made the vendored `gh-stack` skill model-invocable again in Codex, Claude, and Antigravity: its `agents/openai.yaml` flag was removed. That skill prescribes `gh stack submit --auto`, while the house `git-stack` skill, which stays explicit-only in those harnesses, forbids `submit` because it bypasses `pr-style`. A model can now auto-load the upstream guidance without the house rule.

## Outcome

A model that loads `gh-stack` on its own cannot be led to `gh stack submit` against the house rule: either `gh-stack` is explicit-only again, or it carries or points at the `git-stack` constraint.

## Notes

- `.agents/skills/gh-stack/SKILL.md:57` says "Always use `--auto` with `gh stack submit`"; lines 149-150, 234, and 521-528 repeat the command.
- `.agents/skills/git-stack/SKILL.md:178` says "Never run the `submit` subcommand — it auto-generates PR titles/bodies, conflicting with this repo's `pr-style` conventions."
- OMP already advertises both skills.
