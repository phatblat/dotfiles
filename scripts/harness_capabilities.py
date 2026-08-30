"""Capability schema, registry, and divergence register for harness parity.

Copyright: Ben Chatelain. Apache 2.0.

Split out of ``scripts/agent-harnesses.py`` so these capability facts stay
agent-editable while the guard wiring in that module remains human-only
(``~/.agents/harness/hooks/safety.py`` lists agent-harnesses.py as control
plane, because it is the sole consumer of the safety policy).

That split only holds while this module stays off the ``guard`` fast path.
Every caller of the names defined here is reached solely from ``generate``,
``validate``, ``probe``, ``drift``, and ``audit``, and agent-harnesses.py
imports this module inside its non-fast-path block. So an edit here cannot
influence a safety decision. If a fast-path action ever needs something from
this file, move that thing back into the control-plane module rather than
importing this one earlier.

Vocabulary, enforced by ``validate_registry()`` and switched on by the
renderers in ``harness_docs.py``:

``parity``
    Our alignment state for one (harness, capability): ``aligned`` (does it the
    shared way, nothing owed), ``partial`` (works but incomplete or
    unverified), ``divergent`` (permanent upstream difference, never to be
    closed), ``blocked`` (cannot do it yet, upstream-dependent), ``absent`` (no
    such surface and we do not emulate), ``unknown`` (not researched).
``mode``
    How it is achieved: ``native``, ``adapter``, ``emulated``, ``shared``,
    ``none``.
``evidence.kind``
    How we know: ``probe`` (deterministic local check), ``docs`` (upstream
    documentation), ``source`` (upstream source read), ``runtime`` (observed in
    a live session), ``local`` (inspected local generated artifacts), ``none``
    (unresearched).
"""

from __future__ import annotations

from dataclasses import dataclass, field

from harness_drift import PROBE_KINDS
from harness_paths import HARNESSES

PARITY_STATES = ("aligned", "partial", "divergent", "blocked", "absent", "unknown")
MODES = ("native", "adapter", "emulated", "shared", "none")
EVIDENCE_KINDS = ("probe", "docs", "source", "runtime", "local", "none")
PRIORITIES = ("p0", "p1", "p2")


@dataclass(frozen=True)
class Evidence:
    """How a capability cell's claim was checked."""

    kind: str  # probe|docs|source|runtime|local|none
    ref: str = ""  # doc URL, source permalink, or probe kind
    version: str = ""  # harness CLI version the claim was checked against
    date: str = ""  # YYYY-MM-DD


@dataclass(frozen=True)
class Cell:
    """One (harness, capability) intersection."""

    parity: str  # see module docstring
    mode: str = "none"
    surface: str = ""  # the native config key/file that expresses it
    artifacts: tuple[str, ...] = ()  # display paths of generated artifacts
    evidence: Evidence = Evidence("none")
    note: str = ""
    next_action: str = ""
    divergence: str = ""  # divergence id, required iff parity == "divergent"
    probe: dict[str, str] | None = None


@dataclass(frozen=True)
class Capability:
    """One thing the shared harness wants from every harness."""

    id: str  # "<domain>.<name>"
    domain: str
    title: str
    priority: str  # p0|p1|p2
    contract: str  # what the shared harness wants from this capability
    canonical: tuple[str, ...] = ()  # shared source-of-truth display paths
    verify: str = ""  # command that checks it
    porting: str = ""  # portability guidance across harnesses
    note: str = ""
    cells: dict[str, Cell] = field(default_factory=dict)  # slug -> Cell


@dataclass(frozen=True)
class Divergence:
    """A permanent product-level difference, never a gap and never owed work."""

    id: str
    title: str
    capability: str
    reason: str  # why it will not converge
    coping: str  # how the shared harness lives with it
    evidence: Evidence


# Ordered domain id -> human title. Adding a key renders another page; see
# `render_all()` in scripts/agent-harnesses.py.
DOMAINS: dict[str, str] = {
    "instructions": "Instructions",
    "skills": "Skills",
    "commands": "Commands",
    "agents": "Agents",
    "hooks": "Hooks",
    "permissions": "Permissions",
    "mcp": "MCP",
    "models": "Models",
    "sessions": "Sessions",
    "providers": "Providers",
    "profiles": "Profiles",
    "ui": "UI",
    "maintenance": "Maintenance",
}

# How each harness is treated by this repository, rendered as the Role column of
# the index page.
HARNESS_ROLES: dict[str, dict[str, str]] = {
    "claude": {"role": "supported peer", "maintenance": "generated"},
    "codex": {"role": "supported peer", "maintenance": "generated"},
    "opencode": {"role": "new port", "maintenance": "generated"},
    "pi": {"role": "new port", "maintenance": "generated"},
    "omp": {"role": "tracked port", "maintenance": "generated"},
    "antigravity": {"role": "tracked port", "maintenance": "generated"},
    "cursor": {"role": "tracked port", "maintenance": "generated"},
    "grok": {"role": "new port", "maintenance": "generated"},
    "crush": {"role": "new port", "maintenance": "generated"},
}

# The 7 migrated features were state-verified against local generated artifacts
# on this date. Never reuse it for a cell nobody rechecked then.
_LOCAL_2026_06_27 = Evidence(kind="local", date="2026-06-27")
# Probe-backed cells this restructure verified by running the probe.
_PROBED_2026_08_29 = "2026-08-29"

_SHARED = "~/.agents/harness"
_SAFETY = "~/.agents/harness/hooks/safety.py"


def _exists(path: str) -> dict[str, str]:
    """A `file_exists` probe over a HOME-relative path."""
    return {"kind": "file_exists", "path": path}


def _contains(path: str, pattern: str) -> dict[str, str]:
    """A `file_contains` probe over a HOME-relative path."""
    return {"kind": "file_contains", "path": path, "pattern": pattern}


CAPABILITIES: list[Capability] = [
    Capability(
        id="instructions.global",
        domain="instructions",
        title="Global harness instructions",
        priority="p0",
        contract="Global harness instructions load for every session.",
        canonical=("~/.agents/harness/instructions.md",),
        verify="python3 scripts/agent-harnesses.py validate",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
                probe=_exists(".agents/harness/instructions.md"),
            ),
            "codex": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
                probe=_exists(".agents/harness/instructions.md"),
            ),
            "opencode": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
                probe=_exists(".agents/harness/instructions.md"),
            ),
            "pi": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
                probe=_exists(".agents/harness/instructions.md"),
            ),
            "omp": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.omp/agent/APPEND_SYSTEM.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "inlined shared harness instructions + compaction contract "
                    "+ commit attribution"
                ),
                probe=_exists(".omp/agent/APPEND_SYSTEM.md"),
            ),
            "antigravity": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.agents/harness/adapters/antigravity/plugin.json",
                    "~/.gemini/antigravity-cli/settings.json",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity plugin manifest exists, but no "
                    "installed/imported context surface has verified instruction "
                    "loading"
                ),
                next_action=(
                    "Install or import the Antigravity plugin and verify it loads "
                    "shared harness instructions"
                ),
                probe=_exists(".agents/harness/adapters/antigravity/plugin.json"),
            ),
            "cursor": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json",
                    "~/.agents/harness/adapters/cursor/rules/shared-harness.mdc",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Cursor plugin rule points to shared harness "
                    "instructions, but plugin discovery has not been verified"
                ),
                next_action=(
                    "Link or install the Cursor plugin and verify Cursor loads the "
                    "shared-harness rule"
                ),
                probe=_exists(
                    ".agents/harness/adapters/cursor/rules/shared-harness.mdc"
                ),
            ),
            "grok": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.grok/rules/shared-harness.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "inlined shared harness instructions + compaction contract "
                    "+ commit attribution; loaded as a global rules file"
                ),
                probe=_exists(".grok/rules/shared-harness.md"),
            ),
            "crush": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.config/crush/shared-harness.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "inlined shared harness instructions + compaction contract "
                    "+ commit attribution; loaded through option "
                    "global-context-path in the generated crushrc"
                ),
                probe=_exists(".config/crush/shared-harness.md"),
            ),
        },
    ),
    Capability(
        id="instructions.project_file",
        domain="instructions",
        title="Repository instructions file",
        priority="p0",
        contract=(
            "A repository's own agent instructions file is discovered by every "
            "harness, and we record which filename each one reads."
        ),
    ),
    Capability(
        id="instructions.precedence",
        domain="instructions",
        title="Instruction precedence order",
        priority="p1",
        contract=(
            "When global, project, and directory-scoped instructions all apply, "
            "the resolution order is known per harness."
        ),
    ),
    Capability(
        id="skills.shared",
        domain="skills",
        title="Shared skill discovery",
        priority="p0",
        contract="Shared skills load from ~/.agents/skills.",
        canonical=("~/.agents/skills",),
        verify="python3 scripts/agent-harnesses.py inventory --json",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
            ),
            "codex": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
            ),
            "opencode": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
            ),
            "pi": Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
            ),
            "omp": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.agents/skills",),
                evidence=_LOCAL_2026_06_27,
            ),
            "antigravity": Cell(
                parity="partial",
                mode="adapter",
                artifacts=("~/.agents/harness/adapters/antigravity/skills",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity skill wrappers point to shared skills, "
                    "but runtime import has not been verified"
                ),
                next_action=(
                    "Verify agy imports and activates shared skill wrappers from "
                    "the plugin"
                ),
            ),
            "cursor": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/harness/adapters/cursor/skills",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Cursor plugin skill wrappers point to shared "
                    "skills, but runtime discovery has not been verified"
                ),
                next_action=(
                    "Verify Cursor discovers and activates generated shared skill "
                    "wrappers"
                ),
            ),
            "grok": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.agents/skills",),
                evidence=_LOCAL_2026_06_27,
                note="grok scans ~/.agents/skills at the user tier",
            ),
            "crush": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.agents/skills",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated crushrc adds ~/.agents/skills through option "
                    "skill-path; crush's default global skill roots are "
                    "~/.config/crush/skills and ~/.config/agents/skills, so the "
                    "shared root is named explicitly"
                ),
            ),
        },
    ),
    Capability(
        id="skills.discovery_roots",
        domain="skills",
        title="Skill discovery roots",
        priority="p0",
        contract=(
            "Every harness reaches ~/.agents/skills natively or through a "
            "generated pointer, with no hand-copied skill bodies."
        ),
        canonical=("~/.agents/skills",),
    ),
    Capability(
        id="skills.identity",
        domain="skills",
        title="Skill identity and trigger",
        priority="p0",
        contract=(
            "A shared skill's name and trigger description are expressed in the "
            "harness's own skill metadata without forking the shared SKILL.md."
        ),
        porting="Keep `SKILL.md` to standard `name` and `description` first.",
        note="Most portable part of a skill.",
        cells={
            "claude": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
            "codex": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
            "opencode": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
            "pi": Cell(parity="unknown", surface="Local `skills` path adapter"),
            "omp": Cell(parity="unknown", surface="Shared skills path"),
            "antigravity": Cell(parity="unknown", surface="Generated wrapper skill"),
            "cursor": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
            "grok": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
            "crush": Cell(
                parity="unknown", surface="`name`, `description` in `SKILL.md`"
            ),
        },
    ),
    Capability(
        id="skills.manual_only",
        domain="skills",
        title="Manual-only procedural skills",
        priority="p1",
        contract=(
            "A procedural skill the user runs deliberately is not model-invoked, "
            "expressed through whatever key that harness documents."
        ),
        porting=(
            "Represent intent per harness; do not copy one vendor key everywhere."
        ),
        note=(
            "Codex policy blocks implicit invocation but does not hide enabled "
            "skill metadata."
        ),
        cells={
            "claude": Cell(
                parity="unknown", surface="`disable-model-invocation: true`"
            ),
            "codex": Cell(
                parity="unknown",
                surface=(
                    "`agents/openai.yaml` `policy.allow_implicit_invocation: false`"
                ),
            ),
            "opencode": Cell(
                parity="unknown",
                surface=(
                    "No direct equivalent; use skill permissions or command wrappers"
                ),
            ),
            "pi": Cell(parity="unknown", surface="Local adapter or command wrapper"),
            "omp": Cell(parity="unknown", surface="Local adapter or command wrapper"),
            "antigravity": Cell(
                parity="unknown", surface="Local adapter or command wrapper"
            ),
            "cursor": Cell(
                parity="unknown", surface="`disable-model-invocation: true`"
            ),
            "grok": Cell(parity="unknown", surface="`disable-model-invocation: true`"),
            "crush": Cell(parity="unknown", surface="`disable-model-invocation: true`"),
        },
    ),
    Capability(
        id="skills.path_scope",
        domain="skills",
        title="File/path-scoped guidance",
        priority="p2",
        contract=(
            "Guidance that only applies to certain paths is scoped by the "
            "harness's own mechanism rather than loaded unconditionally."
        ),
        porting="Use only where the target harness documents path scoping.",
        note="Not part of the shared Agent Skills core.",
        cells={
            "claude": Cell(parity="unknown", surface="`paths` frontmatter"),
            "codex": Cell(
                parity="unknown",
                surface="Prefer nested repo skills or concise descriptions",
            ),
            "opencode": Cell(
                parity="unknown", surface="Directory discovery plus permissions"
            ),
            "pi": Cell(parity="unknown", surface="Local adapter only"),
            "omp": Cell(parity="unknown", surface="Local adapter only"),
            "antigravity": Cell(parity="unknown", surface="Local adapter only"),
            "cursor": Cell(
                parity="unknown", surface="`paths`; `globs` legacy fallback"
            ),
            "grok": Cell(
                parity="unknown",
                surface="No documented equivalent; scope through the description",
            ),
            "crush": Cell(
                parity="unknown",
                surface="No documented equivalent; scope through the description",
            ),
        },
    ),
    Capability(
        id="skills.tool_preapproval",
        domain="skills",
        title="Skill-level tool preapproval",
        priority="p1",
        contract=(
            "Where a skill needs specific tools preapproved, that is expressed "
            "in the harness's own permission surface, never assumed portable."
        ),
        porting="Treat `allowed-tools` as nonportable and client-specific.",
        note="The Agent Skills spec marks `allowed-tools` experimental.",
        cells={
            "claude": Cell(
                parity="unknown", surface="`allowed-tools` and `disallowed-tools`"
            ),
            "codex": Cell(
                parity="unknown",
                surface=(
                    "Use permissions, hooks, or dependency metadata; no "
                    "skill-level allowlist"
                ),
            ),
            "opencode": Cell(
                parity="unknown",
                surface=(
                    "`permission.skill` controls skill loading, not tool preapproval"
                ),
            ),
            "pi": Cell(parity="unknown", surface="Extension or settings adapter"),
            "omp": Cell(parity="unknown", surface="config.yml tools.approval"),
            "antigravity": Cell(parity="unknown", surface="Hook/adapter guard"),
            "cursor": Cell(
                parity="unknown", surface="No documented skill-level equivalent"
            ),
            "grok": Cell(
                parity="unknown", surface="`allowed-tools` in skill frontmatter"
            ),
            "crush": Cell(
                parity="unknown",
                surface=(
                    "`permissions allow`/`deny` in crushrc; no skill-level allowlist"
                ),
            ),
        },
    ),
    Capability(
        id="skills.ui_metadata",
        domain="skills",
        title="Skill UI metadata",
        priority="p2",
        contract=(
            "Presentation metadata for a shared skill lives in a harness-specific "
            "sidecar so the portable SKILL.md stays vendor-neutral."
        ),
        porting="Keep presentation metadata in harness-specific sidecars.",
        note="Do not put Codex `interface` fields in portable `SKILL.md`.",
        cells={
            "claude": Cell(
                parity="unknown",
                surface="Skill frontmatter or marketplace/plugin metadata",
            ),
            "codex": Cell(
                parity="unknown", surface="`agents/openai.yaml` `interface` fields"
            ),
            "opencode": Cell(
                parity="unknown", surface="`metadata` map only; unknown fields ignored"
            ),
            "pi": Cell(parity="unknown", surface="Local settings/extension only"),
            "omp": Cell(parity="unknown", surface="Local config only"),
            "antigravity": Cell(
                parity="unknown", surface="Plugin manifest or adapter metadata"
            ),
            "cursor": Cell(
                parity="unknown",
                surface="`metadata` map for skills; `.mdc` frontmatter for rules",
            ),
            "grok": Cell(
                parity="unknown", surface="`metadata` map plus `argument-hint`"
            ),
            "crush": Cell(
                parity="unknown", surface="`metadata` map plus `user-invocable`"
            ),
        },
    ),
    Capability(
        id="commands.active",
        domain="commands",
        title="Active shared commands",
        priority="p0",
        contract=(
            "The 27 active commands are available through generated native prompts."
        ),
        canonical=("~/.agents/harness/commands",),
        verify="python3 scripts/agent-harnesses.py inventory --json",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.claude/commands",),
                evidence=_LOCAL_2026_06_27,
                note="source commands",
            ),
            "codex": Cell(
                parity="blocked",
                mode="adapter",
                artifacts=("~/.agents/harness/commands",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "Codex command format not yet stabilized. Last checked "
                    "2026-08-13. Codex uses skills/config instead of native "
                    "command files."
                ),
                next_action="Re-check Codex release notes for stable command format",
            ),
            "opencode": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(
                    "~/.config/opencode/commands",
                    "~/.config/opencode/opencode.jsonc",
                ),
                evidence=_LOCAL_2026_06_27,
                note="generated command templates",
            ),
            "pi": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=("~/.pi/agent/prompts",),
                evidence=_LOCAL_2026_06_27,
                note="generated prompt templates",
            ),
            "omp": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.claude/commands",),
                evidence=_LOCAL_2026_06_27,
            ),
            "antigravity": Cell(
                parity="partial",
                mode="adapter",
                artifacts=("~/.agents/harness/adapters/antigravity/commands",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity command wrappers cover all shared "
                    "prompts, but agy validation only processed a subset as skills"
                ),
                next_action=(
                    "Verify Antigravity command schema or flatten command wrappers "
                    "so all 25 commands are discovered"
                ),
            ),
            "cursor": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/harness/adapters/cursor/commands",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Cursor plugin commands wrap shared prompts, but "
                    "runtime discovery has not been verified"
                ),
                next_action="Verify Cursor discovers all 25 generated command wrappers",
            ),
            "grok": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/skills",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "grok reaches 24 of the 25 command workflows through the "
                    "shared skills; linear/progress has no shared skill, and "
                    "~/.grok/commands wrappers would shadow the same-named shared "
                    "skills"
                ),
                next_action=(
                    "Add a shared skill for the linear/progress workflow so grok "
                    "covers all 25 command workflows"
                ),
            ),
            "crush": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/skills",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "crush has no user-defined slash-command surface, so the "
                    "command workflows are reachable only through the shared "
                    "skills crush discovers; crush's user-invocable skill "
                    "frontmatter cannot be set without forking the shared SKILL.md"
                ),
                next_action=(
                    "Re-check crush releases for a user-defined command surface, or "
                    "teach the shared skill renderer to emit crush-specific "
                    "user-invocable frontmatter"
                ),
            ),
        },
    ),
    Capability(
        id="commands.user_defined",
        domain="commands",
        title="User-defined command surface",
        priority="p1",
        contract=(
            "The 26 shared command prompts are invocable by name in the "
            "harness's own command surface."
        ),
        canonical=("~/.agents/harness/commands",),
    ),
    Capability(
        id="commands.arguments",
        domain="commands",
        title="Command argument substitution",
        priority="p2",
        contract=(
            "A shared command can receive arguments through the harness's own "
            "substitution syntax."
        ),
    ),
    Capability(
        id="agents.specialists",
        domain="agents",
        title="Specialist agents for delegation",
        priority="p0",
        contract="Six specialist agents are represented for delegation.",
        canonical=("~/.agents/harness/agents",),
        verify="python3 scripts/agent-harnesses.py inventory --json",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.claude/agents",),
                evidence=_LOCAL_2026_06_27,
                note="native Claude agents include these plus additional specialists",
            ),
            "codex": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.codex/agents",),
                evidence=_LOCAL_2026_06_27,
                note="native Codex TOML agents",
            ),
            "opencode": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(
                    "~/.config/opencode/agents",
                    "~/.config/opencode/opencode.jsonc",
                ),
                evidence=_LOCAL_2026_06_27,
                note="generated agent config",
            ),
            "pi": Cell(
                parity="partial",
                mode="emulated",
                artifacts=(
                    "~/.pi/agent/agents.json",
                    "~/.pi/agent/extensions/harness.ts",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "Pi specialist delegation policy: model inferred from "
                    "specialist tier (quick=haiku, standard=sonnet, deep=opus); "
                    "fresh session per delegation for context isolation"
                ),
                next_action=(
                    "Implement subprocess delegation in "
                    "~/.pi/agent/extensions/harness.ts per policy"
                ),
            ),
            "omp": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.omp/agent/agents",),
                evidence=_LOCAL_2026_06_27,
                note="generated from shared specialist definitions",
            ),
            "antigravity": Cell(
                parity="partial",
                mode="emulated",
                artifacts=("~/.agents/harness/adapters/antigravity/agents",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity agent wrappers point to shared "
                    "specialists, but isolated delegation has not been verified"
                ),
                next_action=(
                    "Verify Antigravity can delegate to generated specialist "
                    "wrappers with isolated context"
                ),
            ),
            "cursor": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/harness/adapters/cursor/agents",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Cursor plugin agents wrap shared specialists, but "
                    "runtime discovery has not been verified"
                ),
                next_action="Verify Cursor discovers generated specialist agent wrappers",
            ),
            "grok": Cell(
                parity="partial",
                mode="adapter",
                artifacts=("~/.grok/agents",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated grok agent profiles are discovered by grok inspect, "
                    "but spawn_subagent delegation to them has not been verified"
                ),
                next_action=(
                    "Verify grok spawn_subagent can launch the generated specialist "
                    "profiles"
                ),
            ),
            "crush": Cell(
                parity="blocked",
                mode="native",
                artifacts=("~/.agents/harness/agents",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "crush ships exactly two built-in agents (coder, task) and has "
                    "no user-defined agent surface; upstream tracks this as "
                    "charmbracelet/crush#3269"
                ),
                next_action="Re-check crush releases for user-defined agent support",
            ),
        },
    ),
    Capability(
        id="agents.tool_restrictions",
        domain="agents",
        title="Subagent tool restrictions",
        priority="p1",
        contract=(
            "A delegated specialist runs with the tool set its definition allows, "
            "enforced by the harness or by the shared guard."
        ),
        porting=(
            "Prefer native agent configuration; use shared hooks for "
            "cross-harness safety."
        ),
        note="Shared harness guard covers only normalized shell/write/edit safety.",
        cells={
            "claude": Cell(
                parity="unknown",
                surface="Agent `tools`, `disallowedTools`, `permissionMode`",
            ),
            "codex": Cell(
                parity="unknown",
                surface="Agent TOML permissions/sandbox and inherited MCP config",
            ),
            "opencode": Cell(
                parity="unknown", surface="Agent `permission` and `tools`"
            ),
            "pi": Cell(parity="unknown", surface="Extension-enforced guard"),
            "omp": Cell(
                parity="unknown",
                surface="Generated agent wrappers in ~/.omp/agent/agents",
            ),
            "antigravity": Cell(
                parity="unknown", surface="Generated hook/guard adapter"
            ),
            "cursor": Cell(
                parity="unknown",
                surface="Rules/plugin adapter; native behavior unverified",
            ),
            "grok": Cell(
                parity="unknown",
                surface=(
                    "`--tools` / `--disallowed-tools`, subagent `capability_mode`, "
                    "permission rules"
                ),
            ),
            "crush": Cell(
                parity="unknown",
                surface=(
                    "`permissions deny` hides tools; PreToolUse hook for the rest"
                ),
            ),
        },
    ),
    Capability(
        id="agents.user_defined",
        domain="agents",
        title="User-defined agent registration",
        priority="p1",
        contract=(
            "The 6 shared specialist agents are registerable as named agents the "
            "harness can select."
        ),
        canonical=("~/.agents/harness/agents",),
    ),
    Capability(
        id="agents.delegation_isolation",
        domain="agents",
        title="Delegated context isolation",
        priority="p1",
        contract=(
            "A delegated subagent runs in its own context window and returns a "
            "summary rather than inlining into the parent transcript."
        ),
    ),
    Capability(
        id="hooks.safety",
        domain="hooks",
        title="Shared safety guard",
        priority="p0",
        contract=(
            "Dangerous commands, protected writes, and secret-like content are "
            "blocked consistently."
        ),
        canonical=(_SAFETY,),
        verify="python3 scripts/agent-harnesses.py verify",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(_SAFETY,),
                evidence=_LOCAL_2026_06_27,
                probe=_contains(".claude/settings.json", r"bash-guard\.sh"),
            ),
            "codex": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(_SAFETY,),
                evidence=_LOCAL_2026_06_27,
                probe=_contains(".codex/hooks.json", r"bash-guard\.sh"),
            ),
            "opencode": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(_SAFETY,),
                evidence=_LOCAL_2026_06_27,
                probe=_contains(
                    ".config/opencode/plugins/harness.ts", "agent-harnesses"
                ),
            ),
            "pi": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=(_SAFETY,),
                evidence=_LOCAL_2026_06_27,
                probe=_contains(".pi/agent/extensions/harness.ts", "agent-harnesses"),
            ),
            "omp": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=("~/.omp/agent/hooks/pre/harness-guard.ts",),
                evidence=_LOCAL_2026_06_27,
                probe=_contains(
                    ".omp/agent/hooks/pre/harness-guard.ts", "agent-harnesses"
                ),
            ),
            "antigravity": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.agents/harness/adapters/antigravity/hooks/hooks.json",
                    "~/.agents/harness/adapters/antigravity/scripts/harness-guard.py",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity hook wrapper calls the shared guard, "
                    "but native pre-tool blocking has not been verified"
                ),
                next_action=(
                    "Verify Antigravity invokes hooks.json before shell/write/edit "
                    "calls and blocks on deny"
                ),
                probe=_contains(
                    ".agents/harness/adapters/antigravity/hooks/hooks.json",
                    r"harness-guard\.py",
                ),
            ),
            "cursor": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.agents/harness/adapters/cursor/hooks/hooks.json",
                    "~/.agents/harness/adapters/cursor/scripts/harness-guard.py",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "Cursor hook wrapper is generated, but native pre-tool "
                    "blocking behavior has not been verified"
                ),
                next_action=(
                    "Verify Cursor invokes hooks.json before shell/write/edit calls "
                    "and blocks on deny"
                ),
                probe=_contains(
                    ".agents/harness/adapters/cursor/hooks/hooks.json",
                    r"harness-guard\.py",
                ),
            ),
            "grok": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.grok/hooks/harness-guard.json",
                    "~/.grok/scripts/harness-guard.py",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated grok PreToolUse guard maps grok's camelCase payload "
                    "to the shared guard, but live blocking in a grok session has "
                    "not been verified"
                ),
                next_action=(
                    "Verify grok blocks a denied shell command through "
                    "~/.grok/hooks/harness-guard.json in a live session"
                ),
                probe=_contains(".grok/hooks/harness-guard.json", r"harness-guard\.py"),
            ),
            "crush": Cell(
                parity="partial",
                mode="adapter",
                artifacts=(
                    "~/.config/crush/crushrc",
                    "~/.config/crush/hooks/harness-guard.py",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated crush PreToolUse guard maps crush's snake_case "
                    "payload to the shared guard and blocks with exit 2, but crush "
                    "is not installed locally so live blocking is unverified"
                ),
                next_action=(
                    "Install crush and verify it blocks a denied shell command "
                    "through the generated crushrc PreToolUse hook"
                ),
                probe=_contains(".config/crush/crushrc", r"harness-guard\.py"),
            ),
        },
    ),
    Capability(
        id="hooks.events",
        domain="hooks",
        title="Pre-tool-use event",
        priority="p0",
        contract=(
            "The harness exposes a pre-tool-use event that fires before shell, "
            "write, and edit calls."
        ),
    ),
    Capability(
        id="hooks.payload_shape",
        domain="hooks",
        title="Normalized hook payload",
        priority="p0",
        contract=(
            "The harness's hook payload normalizes to "
            "~/.agents/harness/hooks/contract.json without losing tool name, "
            "command, path, content, or cwd."
        ),
        canonical=("~/.agents/harness/hooks/contract.json",),
    ),
    Capability(
        id="hooks.block_protocol",
        domain="hooks",
        title="Hook veto protocol",
        priority="p0",
        contract=(
            "A hook can veto a tool call, and the harness surfaces the shared "
            "guard's reason string to the user."
        ),
    ),
    Capability(
        id="permissions.rules",
        domain="permissions",
        title="Native permission rules",
        priority="p1",
        contract=(
            "Native allow/deny rules are expressed only where they add to, never "
            "weaken, the shared guard decision."
        ),
    ),
    Capability(
        id="permissions.sandbox",
        domain="permissions",
        title="OS-level sandboxing",
        priority="p2",
        contract=(
            "Whether the harness can run tools inside an OS-level sandbox, and "
            "how that interacts with the shared guard."
        ),
    ),
    Capability(
        id="permissions.approval_modes",
        domain="permissions",
        title="Interactive approval modes",
        priority="p1",
        contract=(
            "The harness's interactive approval modes are known, and the default "
            "mode does not bypass the guard."
        ),
    ),
    Capability(
        id="mcp.dependencies",
        domain="mcp",
        title="MCP/tool dependencies",
        priority="p1",
        contract=(
            "A skill or agent that needs an MCP server declares it where the "
            "harness can act on the declaration."
        ),
        porting=(
            "Declare dependencies near the harness that can enforce or install them."
        ),
        note="Dependency metadata is advisory unless the harness enforces it.",
        cells={
            "claude": Cell(
                parity="unknown",
                surface="`.mcp.json`, settings, or agent `mcpServers`",
            ),
            "codex": Cell(
                parity="unknown",
                surface=(
                    "`agents/openai.yaml` `dependencies.tools` plus `config.toml` MCP"
                ),
            ),
            "opencode": Cell(parity="unknown", surface="`mcp` config"),
            "pi": Cell(parity="unknown", surface="Extension or future MCP bridge"),
            "omp": Cell(parity="unknown", surface="~/.omp/agent/mcp.json"),
            "antigravity": Cell(
                parity="unknown", surface="Generated `mcp.json`, unverified"
            ),
            "cursor": Cell(
                parity="unknown", surface="Generated `mcp.json`, unverified"
            ),
            "grok": Cell(
                parity="unknown", surface="`[mcp_servers.*]` in `~/.grok/config.toml`"
            ),
            "crush": Cell(
                parity="unknown", surface="`mcp add` in `~/.config/crush/crushrc`"
            ),
        },
    ),
    Capability(
        id="mcp.transport",
        domain="mcp",
        title="MCP transport and config file",
        priority="p1",
        contract=(
            "MCP servers are declared once per harness with a known transport and "
            "a known config file."
        ),
    ),
    Capability(
        id="mcp.credential_scope",
        domain="mcp",
        title="MCP credential scope",
        priority="p0",
        contract=(
            "MCP credentials come from the environment and are never written into "
            "a tracked harness config file."
        ),
    ),
    Capability(
        id="models.effort",
        domain="models",
        title="Model and effort overrides",
        priority="p1",
        contract=(
            "A shared skill or agent's model and reasoning-effort intent maps to "
            "each harness's own model configuration."
        ),
        porting="Map separately for skills, agents, and global config.",
        note="Never assume model aliases mean the same provider/model.",
        cells={
            "claude": Cell(parity="unknown", surface="Skill/agent `model`, `effort`"),
            "codex": Cell(
                parity="unknown",
                surface="Agent TOML `model`, `model_reasoning_effort`",
            ),
            "opencode": Cell(
                parity="unknown", surface="Global or agent `model`; `small_model`"
            ),
            "pi": Cell(
                parity="unknown", surface="`defaultModel`, `defaultThinkingLevel`"
            ),
            "omp": Cell(parity="unknown", surface="modelRoles, defaultThinkingLevel"),
            "antigravity": Cell(parity="unknown", surface="Not verified in adapter"),
            "cursor": Cell(
                parity="unknown", surface="No shared skill metadata equivalent"
            ),
            "grok": Cell(
                parity="unknown",
                surface=(
                    "Skill `model`, `effort`; persona `model`, `reasoning_effort`"
                ),
            ),
            "crush": Cell(
                parity="unknown",
                surface="`model large`/`model small` with `--reasoning-effort`",
            ),
        },
    ),
    Capability(
        id="models.provider_config",
        domain="models",
        title="Provider and endpoint resolution",
        priority="p1",
        contract=(
            "Which provider and endpoint a model alias resolves to is explicit "
            "in that harness's config, not an undocumented default."
        ),
    ),
    Capability(
        id="models.selection",
        domain="models",
        title="Default model and overrides",
        priority="p1",
        contract=(
            "The default model and the per-session override mechanism are known "
            "per harness."
        ),
    ),
    Capability(
        id="models.small_model",
        domain="models",
        title="Cheap/fast model role",
        priority="p2",
        contract=(
            "Whether the harness has a separate cheap/fast model role, and what "
            "it is used for."
        ),
    ),
    Capability(
        id="sessions.compaction",
        domain="sessions",
        title="Compaction preservation",
        priority="p1",
        contract=(
            "Compaction preserves modified files, branch, pending work, and test state."
        ),
        canonical=("~/.agents/harness/hooks/contract.json",),
        verify="python3 scripts/agent-harnesses.py verify",
        cells={
            "claude": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.claude/settings.json",),
                evidence=_LOCAL_2026_06_27,
                note="native PreCompact hook",
            ),
            "codex": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.codex/hooks.json",),
                evidence=_LOCAL_2026_06_27,
                note="native PreCompact hook",
            ),
            "opencode": Cell(
                parity="aligned",
                mode="adapter",
                artifacts=("~/.config/opencode/plugins/harness.ts",),
                evidence=_LOCAL_2026_06_27,
                note="plugin compaction hook",
            ),
            "pi": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.pi/agent/settings.json",),
                evidence=_LOCAL_2026_06_27,
                note="native compaction settings plus extension status",
            ),
            "omp": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.omp/agent/APPEND_SYSTEM.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "compaction preservation contract inlined with shared harness "
                    "instructions"
                ),
            ),
            "antigravity": Cell(
                parity="partial",
                mode="native",
                artifacts=(
                    "~/.agents/harness/adapters/antigravity/hooks/hooks.json",
                    "~/.gemini/antigravity-cli/settings.json",
                ),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "generated Antigravity compaction guidance records "
                    "preservation requirements, but conversation/artifact behavior "
                    "has not been verified"
                ),
                next_action=(
                    "Verify Antigravity conversation and artifact persistence "
                    "behavior against compact-preservation requirements"
                ),
            ),
            "cursor": Cell(
                parity="partial",
                mode="native",
                artifacts=("~/.agents/harness/adapters/cursor/rules",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "Cursor preservation instructions are generated, but "
                    "resume/history behavior has not been verified"
                ),
                next_action=(
                    "Verify Cursor resume and history behavior against "
                    "compact-preservation requirements"
                ),
            ),
            "grok": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.grok/rules/shared-harness.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "compaction preservation contract inlined in the generated "
                    "grok rules file"
                ),
            ),
            "crush": Cell(
                parity="aligned",
                mode="native",
                artifacts=("~/.config/crush/shared-harness.md",),
                evidence=_LOCAL_2026_06_27,
                note=(
                    "compaction preservation contract inlined in the generated "
                    "crush context file"
                ),
            ),
        },
    ),
    Capability(
        id="sessions.transcript_store",
        domain="sessions",
        title="Transcript store location",
        priority="p1",
        contract=(
            "Transcripts land in the store recorded in SESSION_STORES in "
            "scripts/harness_paths.py, with the env override confirmed."
        ),
        canonical=("~/scripts/harness_paths.py",),
    ),
    Capability(
        id="sessions.resume",
        domain="sessions",
        title="Resume a prior session",
        priority="p1",
        contract="A prior session can be resumed by id from the CLI.",
    ),
    Capability(
        id="sessions.export",
        domain="sessions",
        title="Transcript export",
        priority="p2",
        contract=(
            "A session transcript can be exported to a file in a documented format."
        ),
    ),
    Capability(
        id="providers.auth",
        domain="providers",
        title="Authentication and credential store",
        priority="p1",
        contract="How the harness authenticates and where it stores the credential.",
    ),
    Capability(
        id="providers.custom_endpoint",
        domain="providers",
        title="Self-hosted or proxy endpoint",
        priority="p2",
        contract=(
            "Whether a self-hosted or proxy endpoint can be configured, and by "
            "which key."
        ),
    ),
    Capability(
        id="profiles.named",
        domain="profiles",
        title="Named config profiles",
        priority="p2",
        contract=(
            "Whether the harness supports named config profiles switchable per "
            "invocation."
        ),
    ),
    Capability(
        id="profiles.project_overrides",
        domain="profiles",
        title="Repository config overrides",
        priority="p1",
        contract=(
            "Whether a repository can override global harness config, and which "
            "keys it may override."
        ),
    ),
    Capability(
        id="ui.statusline",
        domain="ui",
        title="Custom status line",
        priority="p2",
        contract=(
            "Whether a custom status line can be configured, and by which key or "
            "script."
        ),
    ),
    Capability(
        id="ui.theme",
        domain="ui",
        title="Theme and light/dark detection",
        priority="p2",
        contract=(
            "Whether the colour theme is configurable and honours terminal "
            "light/dark detection."
        ),
    ),
    Capability(
        id="ui.keybindings",
        domain="ui",
        title="Remappable keybindings",
        priority="p2",
        contract="Whether interactive keybindings are remappable, and where.",
    ),
    Capability(
        id="ui.notifications",
        domain="ui",
        title="Idle and completion notifications",
        priority="p2",
        contract=(
            "Whether the harness can emit a desktop or terminal notification on "
            "idle or completion."
        ),
    ),
    Capability(
        id="maintenance.audit",
        domain="maintenance",
        title="Deterministic parity audit",
        priority="p1",
        contract="Parity can be generated, checked, and audited deterministically.",
        canonical=("~/scripts/agent-harnesses.py", "~/docs/agent-harnesses.json"),
        verify="just harness-check",
        cells={
            slug: Cell(
                parity="aligned",
                mode="shared",
                artifacts=(_SHARED,),
                evidence=_LOCAL_2026_06_27,
            )
            for slug in HARNESSES
        },
    ),
    Capability(
        id="maintenance.config_validation",
        domain="maintenance",
        title="Non-interactive config validation",
        priority="p1",
        contract=(
            "The harness can validate its own config non-interactively, so parity "
            "checks can prove the generated config parses."
        ),
        verify="python3 scripts/agent-harnesses.py validate",
        cells={
            "opencode": Cell(
                parity="aligned",
                mode="native",
                surface="opencode debug config --pure",
                evidence=Evidence(
                    kind="probe", ref="cli_exit_zero", date=_PROBED_2026_08_29
                ),
                probe={"kind": "cli_exit_zero", "args": "debug config --pure"},
            ),
            "pi": Cell(
                parity="aligned",
                mode="native",
                surface="pi list --no-approve",
                evidence=Evidence(
                    kind="probe", ref="cli_exit_zero", date=_PROBED_2026_08_29
                ),
                probe={"kind": "cli_exit_zero", "args": "list --no-approve"},
            ),
        },
    ),
]

DIVERGENCES: list[Divergence] = [
    Divergence(
        id="git.attribution_trailer",
        title="Each harness stamps its own commit co-author identity",
        capability="instructions.global",
        reason=(
            "Every vendor ships a product identity in its commit trailer and has no "
            "reason to adopt another's: crush emits `Co-Authored-By: Crush "
            "<crush@charm.land>`, grok emits `Co-Authored-By: grokkybara[bot] "
            "<304785771+grokkybara[bot]@users.noreply.github.com>`, omp emits "
            "`Co-Authored-By: oh-my-pi <omp@can.ac>`, and Claude Code emits "
            "`Co-Authored-By: Claude <noreply@anthropic.com>`."
        ),
        coping=(
            "The generated per-harness context file is the single source of the "
            "trailer and names that harness's own identity; where the harness also "
            "has a native attribution setting it is switched off so exactly one "
            "mechanism emits one trailer (crush: `option "
            "attribution-trailer-style none` in the generated crushrc)."
        ),
        evidence=Evidence(
            kind="local", ref="~/.config/crush/shared-harness.md", date="2026-08-29"
        ),
    ),
]


def cell_for(capability: Capability, slug: str) -> Cell:
    """Return the declared cell, or an all-unknown cell when none is declared.

    This is what lets an unresearched capability render as unknown for every
    harness without writing nine stub cells per capability.
    """
    declared = capability.cells.get(slug)
    if declared is not None:
        return declared
    return Cell(parity="unknown")


def validate_registry() -> list[str]:
    """Return registry invariant violations, empty when the registry is clean."""
    errors: list[str] = []
    seen: set[str] = set()
    divergence_ids = {item.id for item in DIVERGENCES}
    capability_ids = {item.id for item in CAPABILITIES}

    for capability in CAPABILITIES:
        label = capability.id
        if label in seen:
            errors.append(f"capability {label} is declared twice")
        seen.add(label)
        domain, _, name = label.partition(".")
        if capability.domain not in DOMAINS:
            errors.append(f"capability {label} has unknown domain {capability.domain}")
        if not name or domain != capability.domain:
            errors.append(f"capability {label} id is not '{capability.domain}.<name>'")
        if capability.priority not in PRIORITIES:
            errors.append(
                f"capability {label} has priority {capability.priority!r}, "
                f"expected one of {'|'.join(PRIORITIES)}"
            )
        if not capability.contract:
            errors.append(f"capability {label} has no contract sentence")
        if not capability.title:
            errors.append(f"capability {label} has no title")

        for slug, cell in capability.cells.items():
            errors.extend(_cell_errors(label, slug, cell, divergence_ids))

    for divergence in DIVERGENCES:
        if divergence.capability not in capability_ids:
            errors.append(
                f"divergence {divergence.id} names unknown capability "
                f"{divergence.capability}"
            )
        if divergence.evidence.kind not in EVIDENCE_KINDS:
            errors.append(
                f"divergence {divergence.id} has evidence kind "
                f"{divergence.evidence.kind!r}"
            )
    return errors


def _cell_errors(
    label: str, slug: str, cell: Cell, divergence_ids: set[str]
) -> list[str]:
    """Return invariant violations for one declared cell."""
    errors: list[str] = []
    where = f"{label}[{slug}]"
    if slug not in HARNESSES:
        errors.append(f"{where} is not a known harness slug")
    if cell.parity not in PARITY_STATES:
        errors.append(
            f"{where} has parity {cell.parity!r}, expected one of "
            f"{'|'.join(PARITY_STATES)}"
        )
    if cell.mode not in MODES:
        errors.append(f"{where} has mode {cell.mode!r}")
    if cell.evidence.kind not in EVIDENCE_KINDS:
        errors.append(f"{where} has evidence kind {cell.evidence.kind!r}")

    if cell.parity == "divergent":
        if not cell.divergence:
            errors.append(f"{where} is divergent without a divergence id")
        elif cell.divergence not in divergence_ids:
            errors.append(f"{where} names unknown divergence {cell.divergence}")
        if cell.next_action:
            errors.append(
                f"{where} is divergent and must not carry a next_action; a "
                "permanent difference is never owed work"
            )
    elif cell.divergence:
        errors.append(f"{where} names a divergence but parity is {cell.parity!r}")

    if cell.parity in {"partial", "blocked"} and not cell.next_action:
        errors.append(f"{where} is {cell.parity} without a next_action")

    if cell.parity == "unknown":
        # `surface` is deliberately permitted here: the 72 cells migrated from
        # ATTRIBUTE_MAPPINGS record how each harness expresses a capability,
        # which was researched long before any parity verdict. Dropping that
        # prose to satisfy this rule would destroy recorded research.
        if cell.evidence.kind != "none":
            errors.append(
                f"{where} is unknown but claims {cell.evidence.kind} evidence"
            )
        if cell.next_action:
            errors.append(f"{where} is unknown but carries a next_action")
        if cell.probe is not None:
            errors.append(f"{where} is unknown but declares a probe")
    elif cell.evidence.kind == "none":
        errors.append(f"{where} claims parity {cell.parity} with no evidence")

    if cell.probe is not None:
        kind = cell.probe.get("kind", "")
        if kind not in PROBE_KINDS:
            errors.append(f"{where} declares probe kind {kind!r}")
    return errors


def coverage(capabilities: list[Capability]) -> tuple[int, int]:
    """Return (cells with evidence, total cells) across every harness."""
    verified = sum(
        1
        for capability in capabilities
        for slug in HARNESSES
        if cell_for(capability, slug).evidence.kind != "none"
    )
    return verified, len(capabilities) * len(HARNESSES)


def escape_cell(value: str) -> str:
    """Escape a value for embedding in a markdown table cell."""
    return value.replace("|", "\\|").replace("\n", "<br>")
