"""Renderers for the harness capability knowledge base.

Copyright: Ben Chatelain. Apache 2.0.

Split out of ``scripts/agent-harnesses.py`` so these rendering rules stay
agent-editable while the guard wiring in that module remains human-only
(``~/.agents/harness/hooks/safety.py`` lists agent-harnesses.py as control
plane, because it is the sole consumer of the safety policy).

That split only holds while this module stays off the ``guard`` fast path.
Every caller of the names defined here is reached solely from ``generate``,
``validate``, and ``audit``, and agent-harnesses.py imports this module inside
its non-fast-path block. So an edit here cannot influence a safety decision.

``build_state()`` is the single build of the machine state every page renders
from. It must stay deterministic: same inputs, same bytes. It never probes and
never reads the clock, because ``generate --check`` is what parity checking
relies on for idempotence.

Markdown cell escaping is imported from ``harness_capabilities`` rather than
redefined here; the generator's ``escape_markdown_cell`` and
``harness_paths._escape_cell`` were byte-identical copies of it.
"""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from harness_capabilities import (
    CAPABILITIES,
    DIVERGENCES,
    DOMAINS,
    HARNESS_ROLES,
    PARITY_STATES,
    Cell,
    cell_for,
    coverage,
    escape_cell,
)
from harness_paths import HARNESS_LABELS, HARNESSES

# Parity states counted in the index summary tables, in reporting order.
_COUNTED_PARITY = PARITY_STATES

_managed_header: str | None = None


def configure(*, managed_header: str) -> None:
    """Inject the managed-file header owned by the control-plane module."""
    global _managed_header
    _managed_header = managed_header


def _header() -> str:
    if _managed_header is None:  # pragma: no cover - configure() precedes rendering
        raise RuntimeError("harness_docs.configure() must run before rendering")
    return _managed_header


def build_state(
    *,
    observed: dict[str, Any],
    versions: dict[str, Any],
    plugins: dict[str, Any],
) -> dict[str, Any]:
    """Merge the registry, probe observations, and CLI versions into one state.

    Cells are materialized for every harness through ``cell_for`` so consumers
    never have to know the unknown-by-default rule.
    """
    verified, total = coverage(CAPABILITIES)
    capabilities = [
        {
            "id": capability.id,
            "domain": capability.domain,
            "title": capability.title,
            "priority": capability.priority,
            "contract": capability.contract,
            "canonical": list(capability.canonical),
            "verify": capability.verify,
            "porting": capability.porting,
            "note": capability.note,
            "cells": {
                slug: _materialize_cell(
                    cell_for(capability, slug),
                    observation=observed.get(slug, {}).get(capability.id, {}),
                    version=versions.get(slug, {}).get("version", ""),
                )
                for slug in HARNESSES
            },
        }
        for capability in CAPABILITIES
    ]
    return {
        "schema": 2,
        "generated_from": "scripts/agent-harnesses.py",
        "coverage": {"verified": verified, "total": total},
        "domains": dict(DOMAINS),
        "harnesses": {
            slug: {
                "label": HARNESS_LABELS[slug],
                "role": HARNESS_ROLES[slug]["role"],
                "maintenance": HARNESS_ROLES[slug]["maintenance"],
            }
            for slug in HARNESSES
        },
        "capabilities": capabilities,
        "divergences": [
            {
                "id": divergence.id,
                "title": divergence.title,
                "capability": divergence.capability,
                "reason": divergence.reason,
                "coping": divergence.coping,
                "evidence": {
                    "kind": divergence.evidence.kind,
                    "ref": divergence.evidence.ref,
                    "version": divergence.evidence.version,
                    "date": divergence.evidence.date,
                },
            }
            for divergence in DIVERGENCES
        ],
        "plugins": plugins,
        "versions": versions,
    }


def _materialize_cell(
    cell: Cell, *, observation: dict[str, Any], version: str
) -> dict[str, Any]:
    """Apply the probe-to-parity coupling rule to one declared cell.

    A probe never sets parity. A passing probe supplies evidence; a failing one
    degrades a declared `aligned` cell to `partial` and says why; an
    unavailable one leaves the declared verdict and evidence untouched, because
    an uninstalled harness is not a regression.
    """
    parity = cell.parity
    note = cell.note
    evidence = {
        "kind": cell.evidence.kind,
        "ref": cell.evidence.ref,
        "version": cell.evidence.version,
        "date": cell.evidence.date,
    }
    result = observation.get("result", "") if cell.probe else ""
    detail = observation.get("detail", "")
    if result in {"pass", "fail"}:
        evidence = {
            "kind": "probe",
            "ref": cell.probe["kind"] if cell.probe else "",
            "version": version,
            "date": observation.get("date", ""),
        }
    if result == "fail":
        note = _join_note(note, f"probe failed: {detail}")
        if parity == "aligned":
            parity = "partial"
    elif result == "unavailable":
        note = _join_note(note, f"probe unavailable: {detail}")
    return {
        "parity": parity,
        "mode": cell.mode,
        "surface": cell.surface,
        "artifacts": list(cell.artifacts),
        "evidence": evidence,
        "note": note,
        "next_action": cell.next_action,
        "divergence": cell.divergence,
        "probe": dict(cell.probe) if cell.probe else None,
    }


def _join_note(note: str, suffix: str) -> str:
    return f"{note}; {suffix}" if note else suffix


def render_index(state: dict[str, Any], records: list[dict[str, Any]]) -> str:
    """Render docs/agent-harnesses.md, the entry point to the knowledge base.

    `records` is the drift ledger, newest first; the last ten are summarized
    here and the full view lives on the drift page.
    """
    verified = state["coverage"]["verified"]
    total = state["coverage"]["total"]
    percent = round(100 * verified / total) if total else 0
    lines = [
        "# Agent Harness Parity",
        "",
        _header(),
        "",
        f"Coverage: {verified}/{total} cells verified ({percent}%)",
        "",
        "## Harnesses",
        "",
        "| Harness | Role | CLI version | First seen | "
        + " | ".join(name.capitalize() for name in _COUNTED_PARITY)
        + " |",
        "|---|---|---|---|" + "---|" * len(_COUNTED_PARITY),
    ]
    for slug in HARNESSES:
        counts = _parity_counts(
            capability["cells"][slug] for capability in state["capabilities"]
        )
        version = state["versions"].get(slug, {})
        lines.append(
            f"| {slug} | {state['harnesses'][slug]['role']} "
            f"| {escape_cell(version.get('version') or '-')} "
            f"| {version.get('first_seen') or '-'} | "
            + " | ".join(str(counts[name]) for name in _COUNTED_PARITY)
            + " |"
        )

    lines.extend(
        [
            "",
            "## Domains",
            "",
            "| Domain | Page | Capabilities | "
            + " | ".join(name.capitalize() for name in _COUNTED_PARITY)
            + " |",
            "|---|---|---|" + "---|" * len(_COUNTED_PARITY),
        ]
    )
    for domain, title in state["domains"].items():
        owned = [item for item in state["capabilities"] if item["domain"] == domain]
        counts = _parity_counts(
            cell for item in owned for cell in item["cells"].values()
        )
        lines.append(
            f"| {title} | [harness/{domain}.md](harness/{domain}.md) "
            f"| {len(owned)} | "
            + " | ".join(str(counts[name]) for name in _COUNTED_PARITY)
            + " |"
        )

    lines.extend(["", "## Open items", ""])
    open_items = [
        (slug, item["id"], item["cells"][slug]["next_action"])
        for slug in HARNESSES
        for item in state["capabilities"]
        if item["cells"][slug]["next_action"]
    ]
    if open_items:
        lines.extend(["| Harness | Capability | Next action |", "|---|---|---|"])
        # One row per cell. Never join two harnesses' actions into one cell:
        # an unattributed list is what this page replaced.
        for slug, capability_id, next_action in sorted(
            open_items, key=lambda row: (HARNESSES.index(row[0]), row[1])
        ):
            lines.append(f"| {slug} | {capability_id} | {escape_cell(next_action)} |")
    else:
        lines.append("No open items.")

    lines.extend(["", "## Recent drift", ""])
    recent = records[:10]
    if recent:
        lines.extend(
            [
                "| Date | Harness | Capability | Field | From | To |",
                "|---|---|---|---|---|---|",
            ]
        )
        lines.extend(_drift_row(record, versioned=False) for record in recent)
    else:
        lines.append("No drift recorded yet.")

    lines.extend(["", "## Permanent divergences", ""])
    if state["divergences"]:
        lines.extend(
            (f"- `{item['id']}` — {item['title']} ([details](harness/divergence.md))")
            for item in state["divergences"]
        )
    else:
        lines.append("None recorded.")

    lines.extend(
        [
            "",
            "## Pages",
            "",
            (
                "- [Porting grid](harness/porting.md) — every harness's native "
                "surface for one capability on one row."
            ),
            (
                "- [Permanent divergences](harness/divergence.md) — differences "
                "that will never be closed."
            ),
            (
                "- [Drift ledger](harness/drift.md) — what changed, when, and at "
                "which CLI version."
            ),
            (
                "- [Native plugins](harness/plugins.md) — configured plugin "
                "state per harness."
            ),
            "",
        ]
    )
    return "\n".join(lines)


def render_domain_page(state: dict[str, Any], domain: str) -> str:
    """Render docs/harness/<domain>.md, one transposed table per capability."""
    owned = [item for item in state["capabilities"] if item["domain"] == domain]
    lines = [
        f"# {state['domains'][domain]}",
        "",
        _header(),
        "",
        (
            f"{len(owned)} capabilities. Index: "
            "[docs/agent-harnesses.md](../agent-harnesses.md)"
        ),
        "",
    ]
    unresearched = [
        item
        for item in owned
        if all(cell["parity"] == "unknown" for cell in item["cells"].values())
    ]
    unresearched_ids = {item["id"] for item in unresearched}
    for item in owned:
        if item["id"] in unresearched_ids:
            continue
        lines.extend(_capability_section(item))
    if unresearched:
        lines.extend(["### Not yet researched", ""])
        lines.extend(
            f"- `{item['id']}` · {item['priority']} — {item['contract']}"
            for item in unresearched
        )
        lines.append("")
    return "\n".join(lines)


def _capability_section(item: dict[str, Any]) -> list[str]:
    """Render one capability: its contract, its metadata, its harness rows."""
    lines = [f"### {item['id']} · {item['priority']}", "", item["contract"], ""]
    if item["canonical"]:
        lines.append(
            "Canonical: " + ", ".join(f"`{path}`" for path in item["canonical"])
        )
    if item["verify"]:
        lines.append(f"Verify: `{item['verify']}`")
    if item["porting"]:
        lines.append(f"Porting: {item['porting']}")
    if item["note"]:
        lines.append(f"Note: {item['note']}")
    divergences = sorted(
        {
            cell["divergence"]
            for cell in item["cells"].values()
            if cell["parity"] == "divergent" and cell["divergence"]
        }
    )
    if divergences:
        lines.append(
            "Divergence: "
            + ", ".join(f"[`{item_id}`](divergence.md)" for item_id in divergences)
        )
    if lines[-1] != "":
        lines.append("")
    lines.extend(
        [
            "| Harness | Parity | Mode | Native surface | Evidence | Note |",
            "|---|---|---|---|---|---|",
        ]
    )
    for slug in HARNESSES:
        cell = item["cells"][slug]
        lines.append(
            f"| {slug} | {cell['parity']} | {cell['mode']} "
            f"| {escape_cell(cell['surface']) or '-'} "
            f"| {_format_evidence(cell['evidence'])} "
            f"| {escape_cell(cell['note']) or '-'} |"
        )
    lines.append("")
    return lines


def _format_evidence(evidence: dict[str, str]) -> str:
    """Render evidence as `kind · version · date`, or `-` when unresearched."""
    if evidence["kind"] == "none":
        return "-"
    parts = [evidence["kind"], evidence["version"] or "-", evidence["date"] or "-"]
    return escape_cell(" · ".join(parts))


def render_porting_page(state: dict[str, Any]) -> str:
    """Render docs/harness/porting.md, the deliberately wide porting grid.

    Kept off the index because comparing all nine harnesses on one row is the
    actual porting workflow, and that is the one job a wide table is good at.
    """
    lines = [
        "# Porting Grid",
        "",
        _header(),
        "",
        (
            "Use this table when porting shared skills, commands, agents, and "
            "safety rules between harnesses. Only the `SKILL.md` core `name` and "
            "`description` fields should be treated as broadly portable. Other "
            "metadata is harness-specific unless the target documentation says "
            "otherwise. When porting research changes current agent "
            "configuration facts, update `CAPABILITIES` in "
            "`scripts/harness_capabilities.py` and regenerate this document."
        ),
        "",
        "| Capability | Portable guidance | "
        + " | ".join(HARNESS_LABELS[slug] for slug in HARNESSES)
        + " | Notes |",
        "|---|---|" + "---|" * len(HARNESSES) + "---|",
    ]
    for item in state["capabilities"]:
        surfaces = [item["cells"][slug]["surface"] for slug in HARNESSES]
        if not item["porting"] and not any(surfaces):
            continue
        cells = " | ".join(escape_cell(surface) or "-" for surface in surfaces)
        lines.append(
            f"| `{item['id']}` | {escape_cell(item['porting']) or '-'} | {cells} "
            f"| {escape_cell(item['note']) or '-'} |"
        )
    lines.extend(
        [
            "",
            "### Mapping Sources",
            "",
            "- Open Agent Skills spec: https://agentskills.io/specification",
            "- Claude Code slash commands and subagents: https://docs.anthropic.com/en/docs/claude-code/slash-commands and https://code.claude.com/docs/en/sub-agents",
            "- Codex skills and subagents: https://developers.openai.com/codex/skills and https://developers.openai.com/codex/subagents",
            "- OpenCode config and skills: https://opencode.ai/docs/config/ and https://opencode.ai/docs/skills/",
            "- Cursor rules and skills: https://cursor.com/docs/rules and https://cursor.com/docs/skills",
            "- Pi, OMP, and Antigravity rows reflect local generated adapters in this repository until primary docs are verified.",
            "",
        ]
    )
    return "\n".join(lines)


def render_divergence_page(state: dict[str, Any]) -> str:
    """Render docs/harness/divergence.md, the permanent-difference register."""
    lines = [
        "# Permanent Divergences",
        "",
        _header(),
        "",
        (
            "A divergence is a product-level difference that will never be "
            "closed. It is not a gap and never carries a next action; a cell "
            "that names one is `divergent`, not `partial`."
        ),
        "",
    ]
    if not state["divergences"]:
        lines.extend(["None recorded.", ""])
        return "\n".join(lines)
    for item in state["divergences"]:
        lines.extend(
            [
                f"### {item['id']}",
                "",
                item["title"],
                "",
                f"- Capability: `{item['capability']}`",
                f"- Reason: {item['reason']}",
                f"- How we cope: {item['coping']}",
                f"- Evidence: {_format_evidence(item['evidence'])}"
                + (f" ({item['evidence']['ref']})" if item["evidence"]["ref"] else ""),
                "",
            ]
        )
    return "\n".join(lines)


def render_drift_page(state: dict[str, Any], records: list[dict[str, Any]]) -> str:
    """Render docs/harness/drift.md: current CLI versions, then the ledger."""
    lines = [
        "# Drift Ledger",
        "",
        _header(),
        "",
        (
            "What changed since the last `just harness-probe`, newest first. "
            "`docs/harness/drift.jsonl` is the full append-only record and "
            "`docs/harness/versions.json` the current version snapshot."
        ),
        "",
        "## Current CLI versions",
        "",
        "| Harness | Version | First seen | Previous |",
        "|---|---|---|---|",
    ]
    for slug in HARNESSES:
        version = state["versions"].get(slug, {})
        lines.append(
            f"| {slug} | {escape_cell(version.get('version') or '-')} "
            f"| {version.get('first_seen') or '-'} "
            f"| {escape_cell(version.get('previous') or '-')} |"
        )
    lines.extend(["", "## Records", ""])
    if not records:
        lines.extend(["No drift recorded yet.", ""])
        return "\n".join(lines)
    lines.extend(
        [
            "| Date | Harness | Capability | Field | From | To | Version |",
            "|---|---|---|---|---|---|---|",
        ]
    )
    lines.extend(_drift_row(record, versioned=True) for record in records[:200])
    lines.append("")
    return "\n".join(lines)


def _drift_row(record: dict[str, Any], *, versioned: bool) -> str:
    """Render one ledger record; the drift page adds the version column."""
    cells = [
        str(record.get("date", "")),
        str(record.get("harness", "")),
        str(record.get("capability", "")),
        str(record.get("field", "")),
        str(record.get("from", "")),
        str(record.get("to", "")),
    ]
    if versioned:
        cells.append(str(record.get("version_to", "")))
    return "| " + " | ".join(escape_cell(cell) or "-" for cell in cells) + " |"


def render_plugins_page(state: dict[str, Any]) -> str:
    """Render docs/harness/plugins.md, the configured native plugin matrix."""
    plugins = state["plugins"]
    plugin_ids = sorted(
        {
            entry["id"]
            for harness_entries in plugins.values()
            for entry in harness_entries
        }
    )
    configured_by_harness = {
        harness: {entry["id"]: entry for entry in entries}
        for harness, entries in plugins.items()
    }
    lines = [
        "# Harness Plugins",
        "",
        _header(),
        "",
        (
            "Configured native plugin state, from the harness config files. "
            "`just harness-audit` compares this against what each CLI reports "
            "as installed."
        ),
        "",
        "## Native Plugins",
        "",
        "| Plugin | Claude | Codex |",
        "|---|---|---|",
    ]
    for plugin_id in plugin_ids:
        lines.append(
            "| {plugin} | {claude} | {codex} |".format(
                plugin=escape_cell(plugin_id),
                claude=format_plugin_state(
                    configured_by_harness["claude"].get(plugin_id)
                ),
                codex=format_plugin_state(
                    configured_by_harness["codex"].get(plugin_id)
                ),
            )
        )
    lines.append("")
    return "\n".join(lines)


def format_plugin_state(value: dict[str, Any] | None) -> str:
    """Render one configured plugin entry as missing/enabled/disabled."""
    if value is None:
        return "missing"
    return "enabled" if value["enabled"] else "disabled"


def _parity_counts(cells: Iterable[dict[str, Any]]) -> dict[str, int]:
    """Count parity states over an iterable of materialized cells."""
    counts: dict[str, int] = dict.fromkeys(_COUNTED_PARITY, 0)
    for cell in cells:
        parity = cell["parity"]
        if parity in counts:
            counts[parity] += 1
    return counts
