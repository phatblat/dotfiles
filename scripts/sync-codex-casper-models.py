#!/usr/bin/env python3
"""Generate ~/.codex/casper.models.json from the live Casper catalog.

Codex has no metadata for Casper's models, so it falls back to placeholder
metadata (unknown context window, OpenAI model names advertised to sub-agents).
This mirrors `GET /v1/models` into the schema `model_catalog_json` expects.
"""

import json
import os
import urllib.request

BASE = "https://casper-api.ditto.live/v1"
OUT = os.path.expanduser("~/.codex/casper.models.json")

PLACEHOLDER = (
    "Unused: `model_instructions_file` in casper.config.toml supplies the real "
    "prompt. The catalog schema requires a non-empty value here."
)

EFFORTS = [
    {"effort": "low", "description": "Fast responses with lighter reasoning"},
    {"effort": "medium", "description": "Balances speed and reasoning depth for everyday tasks"},
    {"effort": "high", "description": "Greater reasoning depth for complex problems"},
]


def display_name(slug: str) -> str:
    special = {
        "auto": "Casper Auto",
        "gpt-oss-120b": "GPT-OSS 120B",
        "dittoaicoder": "Ditto AI Coder",
        "glm-4.7": "GLM 4.7",
        "glm-5.2": "GLM 5.2",
        "glm-5.2-fast": "GLM 5.2 Fast",
    }
    if slug in special:
        return special[slug]
    return slug.replace("-", " ").title().replace("Glm", "GLM").replace("Kimi K", "Kimi K")


def main() -> None:
    key = os.environ["CASPER_API_KEY"]
    req = urllib.request.Request(f"{BASE}/models", headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=30) as r:
        catalog = json.load(r)["data"]

    models = []
    for idx, m in enumerate(sorted(catalog, key=lambda m: m["id"]), start=1):
        slug = m["id"]
        window = m.get("context_length") or m.get("max_model_len")
        # Only `reasoning_effort` models take Codex's reasoning.effort field; the
        # rest gate thinking through a chat-template switch Codex cannot set.
        efforts = EFFORTS if m.get("reasoning_param") == "reasoning_effort" else []
        entry = {
            "slug": slug,
            "display_name": display_name(slug),
            "description": f"Casper router model `{slug}`.",
            "context_window": window,
            "max_context_window": window,
            "effective_context_window_percent": 95,
            "input_modalities": ["text"],
            "supported_reasoning_levels": efforts,
            "shell_type": "shell_command",
            "truncation_policy": {"mode": "tokens", "limit": 10000},
            "experimental_supported_tools": [],
            "support_verbosity": False,
            "supported_in_api": True,
            "visibility": "list",
            "priority": idx,
            "base_instructions": PLACEHOLDER,
        }
        if efforts:
            entry["default_reasoning_level"] = "high"
        models.append(entry)

    with open(OUT, "w") as f:
        json.dump({"models": models}, f, indent=2)
        f.write("\n")
    print(f"wrote {OUT}: {len(models)} models")
    for m in models:
        print(f"  {m['slug']:24} {m['context_window']:>9} ctx  reasoning={bool(m['supported_reasoning_levels'])}")


if __name__ == "__main__":
    main()
