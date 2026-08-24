"""Skill-pointer rendering for the shared agent harness.

Copyright: Ben Chatelain. Apache 2.0.

Split out of ``scripts/agent-harnesses.py`` so these rendering rules stay
agent-editable while the guard wiring in that module remains human-only
(``~/.agents/harness/hooks/safety.py`` lists agent-harnesses.py as control
plane, because it is the sole consumer of the safety policy).

That split only holds while this module stays off the ``guard`` fast path.
Every caller of the names defined here -- ``render_all()`` and
``find_obsolete_skill_wrappers()`` -- is reached solely from ``generate`` and
``validate``, and agent-harnesses.py imports this module inside its
non-fast-path block. So an edit here cannot influence a safety decision. If a
fast-path action ever needs something from this file, move that thing back into
the control-plane module rather than importing this one earlier.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

# Skills that get a native pointer file in each harness's own skills directory,
# rather than only the generated antigravity/cursor adapter copies.
#
# `retro` is deliberately absent: ~/.claude/skills/retro is the gstack skill
# (1812 lines), unrelated to the 54-line shared harness-cleanup skill of the
# same name, and generating a pointer over it would destroy it. `boris` is
# absent because it is Claude-Code-specific, externally compiled, and
# self-updating from a URL.
NATIVE_SKILL_ADAPTERS = {
    "aven",
    "brainstorm",
    "branch-finish",
    "ci-fix",
    "container",
    "debug-issue",
    "dispatching-parallel-agents",
    "executing-plans",
    "find-docs",
    "gha-checks",
    "gha-log-reader",
    "git-worktrees",
    "graphify",
    "handoff",
    "ocr",
    "optimize-harness",
    "pr-style",
    "receiving-code-review",
    "refactor-safely",
    "requesting-code-review",
    "resolve-feedback",
    "review-changes",
    "subagent-driven-development",
    "test-driven-development",
    "writing-plans",
}

# Subset of the above that must not be model-invoked: procedural workflows the
# user runs deliberately. Membership mirrors `allow_implicit_invocation: false`
# in each shared skill's agents/openai.yaml, so the two stay consistent.
MANUAL_SKILL_ADAPTERS = {
    "branch-finish",
    "gha-checks",
    "gha-log-reader",
    "git-worktrees",
    "handoff",
    "optimize-harness",
    "resolve-feedback",
}

_managed_header: str | None = None
_skill_source: Path | None = None


def configure(*, managed_header: str, skill_source: Path) -> None:
    """Inject the two values owned by the control-plane module.

    Keeps agent-harnesses.py authoritative for where the harness lives and what
    it stamps on generated files, instead of duplicating either here.
    """
    global _managed_header, _skill_source
    _managed_header = managed_header
    _skill_source = skill_source


def _require_config() -> tuple[str, Path]:
    if _managed_header is None or _skill_source is None:
        raise RuntimeError(
            "harness_skills.configure() must run before rendering skills"
        )
    return _managed_header, _skill_source


def shared_skill_description(skill_name: str) -> str:
    """Return the shared skill's own trigger description.

    The pointer file is the only thing a host reads when deciding whether a
    skill applies, so it has to carry the real trigger. Emitting the path
    instead -- as every renderer here used to -- makes the skill undiscoverable:
    a host cannot tell that `ci-fix` is about failing CI from the string
    "Load the shared skill from ~/.agents/skills/ci-fix/SKILL.md".

    Falls back to that path string only when the shared file has no parseable
    description, which is strictly better than emitting nothing.
    """
    _, skill_source = _require_config()
    fallback = f"Load the shared skill from ~/.agents/skills/{skill_name}/SKILL.md"
    try:
        text = (skill_source / skill_name / "SKILL.md").read_text(encoding="utf-8")
    except OSError:
        return fallback
    front = re.match(r"---\n(.*?)\n---", text, re.DOTALL)
    if not front:
        return fallback
    field = re.search(
        r"^description:[ \t]*(?:[|>][-+]?)?[ \t]*\n?(.*?)(?=^[A-Za-z_][\w-]*:|\Z)",
        front.group(1),
        re.DOTALL | re.MULTILINE,
    )
    if not field:
        return fallback
    # Block scalars ("description: |") span lines; collapse to the single line a
    # frontmatter `description:` value has to be.
    collapsed = " ".join(field.group(1).split())
    # A quoted YAML scalar keeps its delimiters through the regex above; strip
    # one matching pair so the value is not re-quoted when re-emitted.
    if len(collapsed) > 1 and collapsed[0] == collapsed[-1] and collapsed[0] in "\"'":
        collapsed = collapsed[1:-1].strip()
    return collapsed or fallback


def _pointer_body(skill_name: str, *, extra_frontmatter: str = "") -> str:
    managed_header, _ = _require_config()
    # A real description carries quotes, colons and em dashes, none of which
    # survive an unquoted YAML scalar -- `description: says "x": y` does not
    # parse at all. Emit a double-quoted scalar instead: YAML accepts
    # JSON's escape set there, and ensure_ascii=False keeps Unicode readable
    # rather than turning every em dash into \u2014.
    description = json.dumps(shared_skill_description(skill_name), ensure_ascii=False)
    return f"""---
name: {skill_name}
description: {description}{extra_frontmatter}
---

{managed_header}

Load and follow the shared skill at `~/.agents/skills/{skill_name}/SKILL.md`.
"""


# The generated pointer shape, with the description value left free. Obsolete
# wrappers cannot be recognized by re-rendering and comparing bytes: once a
# skill is deleted from the shared tree its description is gone, so a re-render
# yields the fallback text and never equals the leftover file. Matching the
# shape instead identifies a generated wrapper from the file alone, while any
# hand edit -- an appended comment, a reordered key -- fails the anchors and so
# is preserved.
_POINTER_SHAPE = re.compile(
    r"\A---\n"
    r"name: (?P<name>[^\n]*)\n"
    r"description: [^\n]*\n"
    r"(?:disable-model-invocation: true\n)?"
    r"---\n"
    r"\n"
    r"(?P<header>[^\n]*)\n"
    r"\n"
    r"Load and follow the shared skill at "
    r"`~/\.agents/skills/(?P<target>[^`]*)/SKILL\.md`\.\n"
    r"\Z"
)


def is_generated_pointer(text: str, skill_name: str) -> bool:
    """Report whether ``text`` is an unmodified generated pointer for a skill.

    Used to decide whether an adapter wrapper left behind by a deleted skill is
    safe to remove. Deliberately ignores the description value and checks
    everything else exactly, so a stale wrapper is still recognized while a
    hand-modified one is not.
    """
    managed_header, _ = _require_config()
    match = _POINTER_SHAPE.match(text)
    if not match:
        return False
    return (
        match.group("name") == skill_name
        and match.group("header") == managed_header
        and match.group("target") == skill_name
    )


def render_claude_skill(skill_name: str, *, manual_only: bool) -> str:
    extra = "\ndisable-model-invocation: true" if manual_only else ""
    return _pointer_body(skill_name, extra_frontmatter=extra)


def render_codex_skill(skill_name: str) -> str:
    # Codex expresses manual-only through agents/openai.yaml, rendered
    # separately by render_codex_skill_policy(), not through frontmatter.
    return _pointer_body(skill_name)


def render_opencode_skill(skill_name: str) -> str:
    # OpenCode has no documented manual-invocation key; skill loading is
    # controlled by `permission.skill` in its own config instead.
    return _pointer_body(skill_name)


def render_antigravity_skill(skill_name: str) -> str:
    return _pointer_body(skill_name)


def render_cursor_skill(skill_name: str) -> str:
    # Cursor does document `disable-model-invocation`, so this is a known parity
    # gap: wiring it up needs a manual_only argument here and at both call
    # sites in the control-plane module.
    return _pointer_body(skill_name)
