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
    "crush",
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
    "crush": "Crush",
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
    "crush": "crush",
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
    "crush": (".config/crush",),
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
        note=(
            "sessionDir in effective Pi settings wins over env vars; scanner reads "
            "~/.pi/agent/settings.json when present and falls back to "
            "PI_CODING_AGENT_DIR/sessions, then ~/.pi/agent/sessions"
        ),
    ),
    "omp": SessionStore(
        kind="jsonl",
        default=".omp/agent",
        pattern="sessions/**/*.jsonl",
        env=("OMP_PROFILE",),
        verified=True,
        note=(
            "OMP_PROFILE selects ~/.omp/profiles/<profile>/agent/sessions; "
            "default profile uses PI_CODING_AGENT_DIR/sessions or ~/.omp/agent/sessions; "
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
    "crush": SessionStore(
        kind="none",
        default=".local/share/crush",
        pattern="",
        env=("CRUSH_GLOBAL_DATA", "XDG_DATA_HOME"),
        verified=False,
        note=(
            "transcripts live in crush.db, whose schema upstream documents as "
            "not a public API and reshapes through sqlc migrations; parsing it "
            "would break on any crush release, so no scanner reads it and "
            "session coverage is reported as none"
        ),
    ),
}
