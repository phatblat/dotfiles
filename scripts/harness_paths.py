"""Harness inventory data: slugs, labels, attribute mappings, CLI binaries,
config roots, and session-store descriptors for every supported agent harness.

This module decides nothing about safety -- it is pure data plus one pure
rendering helper -- so it lives outside the human-only control plane
(`~/.agents/harness/hooks/safety.py:_CONTROL_PLANE_FRAGMENTS`) and stays
agent-maintainable, mirroring what `harness_skills.py` already does for skill
rendering. `scripts/agent-harnesses.py` imports these names unconditionally
(including on its `guard`/`provenance` fast path), so this module must stay
stdlib-only with no I/O at import time.
"""

from __future__ import annotations

from dataclasses import dataclass

HARNESSES: list[str] = [
    "claude",
    "codex",
    "opencode",
    "pi",
    "omp",
    "antigravity",
    "cursor",
    "grok",
]

# Column headings for the parity matrix. Every HARNESSES entry needs one; the
# renderer iterates HARNESSES so a harness can never be half-added.
HARNESS_LABELS: dict[str, str] = {
    "claude": "Claude",
    "codex": "Codex",
    "opencode": "OpenCode",
    "pi": "Pi",
    "omp": "OMP",
    "antigravity": "Antigravity",
    "cursor": "Cursor",
    "grok": "Grok",
}

# CLI binary invoked for `<binary> --version` in `command_audit`.
CLI_BINARIES: dict[str, str] = {
    "claude": "claude",
    "codex": "codex",
    "opencode": "opencode",
    "pi": "pi",
    "omp": "omp",
    "antigravity": "agy",
    "cursor": "cursor-agent",
    "grok": "grok",
}

# HOME-relative config roots only, at the coarse-grained directory level
# `audit-ignored-config.py`'s ignored-config scan has always used (whole
# top-level dotdir, not the narrower subpath a harness actually reads config
# from -- see `SESSION_STORES` for that narrower, per-store root). Deliberately
# excludes the generated adapter directories under
# `~/.agents/harness/adapters/` (antigravity, cursor): those are tracked,
# generated, and not allowlist-governed, so they have no business in the
# ignored-config scan. Adding an adapter path here would silently widen it.
CONFIG_ROOTS: dict[str, tuple[str, ...]] = {
    "claude": (".claude",),
    "codex": (".codex",),
    "opencode": (".config/opencode",),
    "pi": (".pi",),
    "omp": (".omp",),
    "antigravity": (".gemini",),
    "cursor": (".cursor",),
    "grok": (".grok",),
}


@dataclass(frozen=True)
class SessionStore:
    """Describes where one harness keeps its session transcripts."""

    kind: str  # "jsonl" | "sqlite" | "none"
    default: str  # HOME-relative default root (file included for single-file sqlite stores)
    pattern: str  # glob relative to root for jsonl, "" for sqlite
    env: tuple[str, ...]  # env vars that relocate the root, highest precedence first
    verified: bool  # True only when the override was confirmed from primary output
    note: str  # coverage caveat rendered in the report


# Resolution rule for every slug: first set env var in `env` wins, else
# `HOME/default`. `verified` marks whether that env override was confirmed
# from primary CLI output this session (see
# `~/.agents/skills/optimize-harness/references/session-usage-evidence.md`
# for the Pi/OMP precedence research); unverified entries still get
# resolved and reported, never silently assumed.
SESSION_STORES: dict[str, SessionStore] = {
    "claude": SessionStore(
        kind="jsonl",
        default=".claude",
        pattern="projects/**/*.jsonl",
        env=("CLAUDE_CONFIG_DIR",),
        verified=False,
        note=(
            "CLAUDE_CONFIG_DIR override not confirmed from CLI output; "
            "history.jsonl (raw prompts, no tool events) is out of scope; "
            "recursive pattern also catches nested "
            "<session>/subagents/agent-*.jsonl transcripts, which already "
            "carry isSidechain/agentId per-record so no extra actor logic "
            "is needed"
        ),
    ),
    "codex": SessionStore(
        kind="jsonl",
        default=".codex",
        pattern="sessions/**/rollout-*.jsonl",
        env=("CODEX_HOME",),
        verified=True,
        note="",
    ),
    "opencode": SessionStore(
        kind="sqlite",
        default=".local/share/opencode/opencode.db",
        pattern="",
        env=("XDG_DATA_HOME",),
        verified=False,
        note=(
            "XDG_DATA_HOME override not confirmed from CLI output; local volume is "
            "tiny (37 messages / 58 parts across 1230 sessions) -- report as low "
            "coverage, not as unused features"
        ),
    ),
    "pi": SessionStore(
        kind="jsonl",
        default=".pi/agent",
        pattern="sessions/*.jsonl",
        env=("PI_CODING_AGENT_SESSION_DIR", "PI_CODING_AGENT_DIR"),
        verified=True,
        note="",
    ),
    "omp": SessionStore(
        kind="jsonl",
        default=".omp/agent",
        pattern="sessions/**/*.jsonl",
        env=("OMP_PROFILE", "PI_CODING_AGENT_DIR", "PI_CONFIG_DIR", "XDG_DATA_HOME"),
        verified=True,
        note=(
            "nested subagent jsonl sits beside the parent under the same session "
            "directory; classify by filename form, not just directory"
        ),
    ),
    "antigravity": SessionStore(
        kind="jsonl",
        default=".gemini/antigravity-cli",
        pattern="history.jsonl",
        env=(),
        verified=False,
        note=(
            "conversations/*.pb is protobuf with no published schema and is on the "
            "guard's protected-path list; transcript bodies are out of coverage"
        ),
    ),
    "cursor": SessionStore(
        kind="jsonl",
        default=".cursor",
        pattern="projects/*/agent-transcripts/*/*.jsonl",
        env=(),
        verified=False,
        note="single local file observed; expect a low-coverage report",
    ),
    "grok": SessionStore(
        kind="jsonl",
        default=".grok",
        pattern="sessions/*/*",
        env=(),
        verified=False,
        note=(
            "pattern matches session directories, not files: scan_grok() reads "
            "chat_history.jsonl and events.jsonl by name within each; "
            "updates.jsonl is not currently parsed (its safe discriminators are "
            "documented but unimplemented); session_search.sqlite is an FTS "
            "index over the same transcript text, not an additional source -- "
            "do not read it"
        ),
    ),
}

# Keep this table current whenever harness porting research changes agent
# configuration facts. Regenerate docs after editing.
ATTRIBUTE_MAPPINGS: list[dict[str, str]] = [
    {
        "id": "skill.identity",
        "feature": "Skill identity and trigger",
        "portable_guidance": "Keep `SKILL.md` to standard `name` and `description` first.",
        "claude": "`name`, `description` in `SKILL.md`",
        "codex": "`name`, `description` in `SKILL.md`",
        "opencode": "`name`, `description` in `SKILL.md`",
        "pi": "Local `skills` path adapter",
        "omp": "Shared skills path",
        "antigravity": "Generated wrapper skill",
        "cursor": "`name`, `description` in `SKILL.md`",
        "grok": "`name`, `description` in `SKILL.md`",
        "notes": "Most portable part of a skill.",
    },
    {
        "id": "skill.manual_only",
        "feature": "Manual-only procedural skills",
        "portable_guidance": "Represent intent per harness; do not copy one vendor key everywhere.",
        "claude": "`disable-model-invocation: true`",
        "codex": "`agents/openai.yaml` `policy.allow_implicit_invocation: false`",
        "opencode": "No direct equivalent; use skill permissions or command wrappers",
        "pi": "Local adapter or command wrapper",
        "omp": "Local adapter or command wrapper",
        "antigravity": "Local adapter or command wrapper",
        "cursor": "`disable-model-invocation: true`",
        "grok": "`disable-model-invocation: true`",
        "notes": "Codex policy blocks implicit invocation but does not hide enabled skill metadata.",
    },
    {
        "id": "skill.path_scope",
        "feature": "File/path-scoped guidance",
        "portable_guidance": "Use only where the target harness documents path scoping.",
        "claude": "`paths` frontmatter",
        "codex": "Prefer nested repo skills or concise descriptions",
        "opencode": "Directory discovery plus permissions",
        "pi": "Local adapter only",
        "omp": "Local adapter only",
        "antigravity": "Local adapter only",
        "cursor": "`paths`; `globs` legacy fallback",
        "grok": "No documented equivalent; scope through the description",
        "notes": "Not part of the shared Agent Skills core.",
    },
    {
        "id": "tool.preapproval",
        "feature": "Skill-level tool preapproval",
        "portable_guidance": "Treat `allowed-tools` as nonportable and client-specific.",
        "claude": "`allowed-tools` and `disallowed-tools`",
        "codex": "Use permissions, hooks, or dependency metadata; no skill-level allowlist",
        "opencode": "`permission.skill` controls skill loading, not tool preapproval",
        "pi": "Extension or settings adapter",
        "omp": "config.yml tools.approval",
        "antigravity": "Hook/adapter guard",
        "cursor": "No documented skill-level equivalent",
        "grok": "`allowed-tools` in skill frontmatter",
        "notes": "The Agent Skills spec marks `allowed-tools` experimental.",
    },
    {
        "id": "skill.ui_metadata",
        "feature": "Skill UI metadata",
        "portable_guidance": "Keep presentation metadata in harness-specific sidecars.",
        "claude": "Skill frontmatter or marketplace/plugin metadata",
        "codex": "`agents/openai.yaml` `interface` fields",
        "opencode": "`metadata` map only; unknown fields ignored",
        "pi": "Local settings/extension only",
        "omp": "Local config only",
        "antigravity": "Plugin manifest or adapter metadata",
        "cursor": "`metadata` map for skills; `.mdc` frontmatter for rules",
        "grok": "`metadata` map plus `argument-hint`",
        "notes": "Do not put Codex `interface` fields in portable `SKILL.md`.",
    },
    {
        "id": "model.effort",
        "feature": "Model and effort overrides",
        "portable_guidance": "Map separately for skills, agents, and global config.",
        "claude": "Skill/agent `model`, `effort`",
        "codex": "Agent TOML `model`, `model_reasoning_effort`",
        "opencode": "Global or agent `model`; `small_model`",
        "pi": "`defaultModel`, `defaultThinkingLevel`",
        "omp": "modelRoles, defaultThinkingLevel",
        "antigravity": "Not verified in adapter",
        "cursor": "No shared skill metadata equivalent",
        "grok": "Skill `model`, `effort`; persona `model`, `reasoning_effort`",
        "notes": "Never assume model aliases mean the same provider/model.",
    },
    {
        "id": "agent.tools",
        "feature": "Subagent tool restrictions",
        "portable_guidance": "Prefer native agent configuration; use shared hooks for cross-harness safety.",
        "claude": "Agent `tools`, `disallowedTools`, `permissionMode`",
        "codex": "Agent TOML permissions/sandbox and inherited MCP config",
        "opencode": "Agent `permission` and `tools`",
        "pi": "Extension-enforced guard",
        "omp": "Generated agent wrappers in ~/.omp/agent/agents",
        "antigravity": "Generated hook/guard adapter",
        "cursor": "Rules/plugin adapter; native behavior unverified",
        "grok": "`--tools` / `--disallowed-tools`, subagent `capability_mode`, permission rules",
        "notes": "Shared harness guard covers only normalized shell/write/edit safety.",
    },
    {
        "id": "mcp.dependencies",
        "feature": "MCP/tool dependencies",
        "portable_guidance": "Declare dependencies near the harness that can enforce or install them.",
        "claude": "`.mcp.json`, settings, or agent `mcpServers`",
        "codex": "`agents/openai.yaml` `dependencies.tools` plus `config.toml` MCP",
        "opencode": "`mcp` config",
        "pi": "Extension or future MCP bridge",
        "omp": "~/.omp/agent/mcp.json",
        "antigravity": "Generated `mcp.json`, unverified",
        "cursor": "Generated `mcp.json`, unverified",
        "grok": "`[mcp_servers.*]` in `~/.grok/config.toml`",
        "notes": "Dependency metadata is advisory unless the harness enforces it.",
    },
]


def _escape_cell(value: str) -> str:
    """Escape a value for embedding in a markdown table cell."""
    return value.replace("|", "\\|").replace("\n", "<br>")


def render_attribute_table(mappings: list[dict[str, str]]) -> list[str]:
    """Render the Configuration Attribute Mapping section as markdown lines."""
    header = (
        "| Feature | Portable guidance | "
        + " | ".join(HARNESS_LABELS[h] for h in HARNESSES)
        + " | Notes |"
    )
    separator = "|---|---|" + "---|" * len(HARNESSES) + "---|"
    lines = [
        "",
        "## Configuration Attribute Mapping",
        "",
        (
            "Use this table when porting shared skills, commands, agents, and safety "
            "rules between harnesses. Only the `SKILL.md` core `name` and "
            "`description` fields should be treated as broadly portable. Other "
            "metadata is harness-specific unless the target documentation says "
            "otherwise. When porting research changes current agent configuration "
            "facts, update `ATTRIBUTE_MAPPINGS` in `scripts/harness_paths.py` and "
            "regenerate this document."
        ),
        "",
        header,
        separator,
    ]
    for item in mappings:
        cells = " | ".join(_escape_cell(item[h]) for h in HARNESSES)
        lines.append(
            f"| {_escape_cell(item['feature'])} | "
            f"{_escape_cell(item['portable_guidance'])} | {cells} | "
            f"{_escape_cell(item['notes'])} |"
        )
    return lines
