#!/usr/bin/env python3
"""Normalize configured and observed plugins across agent harnesses.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
from typing import Any

from codex_config import load as load_codex_config

HARNESSES = ("claude", "codex")


def configured_plugins(root: Path) -> dict[str, list[dict[str, Any]]]:
    claude_settings = _read_json(root / ".claude" / "settings.json")
    codex_config_path = root / ".codex" / "config.toml"
    codex_config = (
        load_codex_config(codex_config_path) if codex_config_path.exists() else {}
    )

    claude_marketplaces = {
        name: _claude_marketplace_source(value)
        for name, value in claude_settings.get("extraKnownMarketplaces", {}).items()
    }
    codex_marketplaces = {
        name: _codex_marketplace_source(value)
        for name, value in codex_config.get("marketplaces", {}).items()
    }

    return {
        "claude": _configured_entries(
            claude_settings.get("enabledPlugins", {}),
            claude_marketplaces,
        ),
        "codex": _configured_entries(
            {
                plugin_id: value.get("enabled", False)
                for plugin_id, value in codex_config.get("plugins", {}).items()
            },
            codex_marketplaces,
        ),
    }


def _configured_entries(
    enabled_plugins: dict[str, Any],
    marketplaces: dict[str, str | None],
) -> list[dict[str, Any]]:
    return [
        {
            "id": plugin_id,
            "enabled": bool(enabled),
            "marketplace": _marketplace_name(plugin_id),
            "marketplace_source": marketplaces.get(_marketplace_name(plugin_id)),
        }
        for plugin_id, enabled in sorted(enabled_plugins.items())
    ]


def _marketplace_name(plugin_id: str) -> str:
    return plugin_id.rpartition("@")[2] or ""


def _claude_marketplace_source(value: Any) -> str | None:
    if not isinstance(value, dict):
        return None
    source = value.get("source", {})
    if not isinstance(source, dict):
        return None
    if source.get("source") == "github" and source.get("repo"):
        return f"github:{source['repo']}"
    return source.get("url")


def _codex_marketplace_source(value: Any) -> str | None:
    return value.get("source") if isinstance(value, dict) else None


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text()) if path.exists() else {}


def normalize_live_plugins(harness: str, payload: Any) -> list[dict[str, Any]]:
    if harness == "claude":
        if not isinstance(payload, list):
            raise ValueError("expected a JSON array")
        entries = payload
        normalized = [
            {
                "id": str(entry.get("id", "")),
                "version": str(entry.get("version", "")),
                "installed": True,
                "enabled": bool(entry.get("enabled", False)),
                "scope": entry.get("scope"),
            }
            for entry in entries
            if isinstance(entry, dict) and entry.get("id")
        ]
    elif harness == "codex":
        if not isinstance(payload, dict) or not isinstance(
            payload.get("installed"), list
        ):
            raise ValueError("expected an object with an 'installed' array")
        installed = payload["installed"]
        normalized = [
            {
                "id": str(entry.get("pluginId", "")),
                "version": str(entry.get("version", "")),
                "installed": bool(entry.get("installed", True)),
                "enabled": bool(entry.get("enabled", False)),
                "scope": None,
            }
            for entry in installed
            if isinstance(entry, dict) and entry.get("pluginId")
        ]
    else:
        raise ValueError(f"unsupported harness: {harness}")
    return sorted(normalized, key=lambda entry: entry["id"])


def audit_plugins(
    configured: dict[str, list[dict[str, Any]]],
) -> dict[str, Any]:
    observed = {harness: _load_live_plugins(harness) for harness in HARNESSES}
    drift: list[dict[str, Any]] = []

    for harness in HARNESSES:
        if not observed[harness]["available"]:
            continue
        actual = {entry["id"]: entry for entry in observed[harness]["plugins"]}
        expected_plugins = {entry["id"]: entry for entry in configured.get(harness, [])}
        for plugin_id, expected in sorted(expected_plugins.items()):
            current = actual.get(plugin_id)
            if current is None:
                drift.append(
                    {
                        "harness": harness,
                        "id": plugin_id,
                        "field": "installed",
                        "configured": True,
                        "observed": False,
                    }
                )
                continue
            if not current["installed"]:
                drift.append(
                    {
                        "harness": harness,
                        "id": plugin_id,
                        "field": "installed",
                        "configured": True,
                        "observed": False,
                    }
                )
            if current["enabled"] != expected["enabled"]:
                drift.append(
                    {
                        "harness": harness,
                        "id": plugin_id,
                        "field": "enabled",
                        "configured": expected["enabled"],
                        "observed": current["enabled"],
                    }
                )
        for plugin_id in sorted(actual.keys() - expected_plugins.keys()):
            drift.append(
                {
                    "harness": harness,
                    "id": plugin_id,
                    "field": "configured",
                    "configured": False,
                    "observed": True,
                }
            )

    harness_order = {harness: index for index, harness in enumerate(HARNESSES)}
    field_order = {"installed": 0, "enabled": 1, "configured": 2}
    drift.sort(
        key=lambda item: (
            harness_order[item["harness"]],
            item["id"],
            field_order[item["field"]],
        )
    )
    return {"observed": observed, "drift": drift}


def _load_live_plugins(harness: str) -> dict[str, Any]:
    if shutil.which(harness) is None:
        return {
            "available": False,
            "plugins": [],
            "error": f"{harness} command not found",
        }
    try:
        result = subprocess.run(
            [harness, "plugin", "list", "--json"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
    except OSError as exc:
        return {
            "available": False,
            "plugins": [],
            "error": f"{harness} plugin list failed: {exc}",
        }
    if result.returncode != 0:
        return {
            "available": False,
            "plugins": [],
            "error": result.stderr.strip() or f"{harness} plugin list failed",
        }
    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        return {
            "available": False,
            "plugins": [],
            "error": f"invalid {harness} plugin JSON: {exc}",
        }
    try:
        plugins = normalize_live_plugins(harness, payload)
    except ValueError as exc:
        return {
            "available": False,
            "plugins": [],
            "error": f"invalid {harness} plugin schema: {exc}",
        }
    return {
        "available": True,
        "plugins": plugins,
        "error": "",
    }
