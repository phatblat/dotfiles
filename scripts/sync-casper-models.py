#!/usr/bin/env python3
"""Sync Casper model catalog and Fireworks pricing into the OMP casper profile.

Copyright: Ben Chatelain. MIT

Usage: sync-casper-models.py [--dry-run]

Casper's /v1/models lists the whole catalog regardless of entitlement but does
not expose per-token pricing, and omp's catalog has no casper prices. The
Fireworks pricing page (Serverless Standard column) is parsed and each catalog
model's `cost:` line in models.yml is rewritten to match, while every other
line — discovery, thinking ladders, compat, comments — is preserved as-is.

models.yml uses `discovery: { type: openai-models-list }` plus `modelOverrides`,
so context windows and reasoning metadata are supplied at runtime; the sync
owns only `cost:` and `thinking.efforts` lines.
"""

import argparse
import difflib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

CASPER_URL = "https://casper-api.ditto.live/v1/models"
FIREWORKS_PRICING_URL = "https://docs.fireworks.ai/serverless/pricing.md"
MODELS_YML = (
    Path(__file__).resolve().parent.parent / ".omp/profiles/casper/agent/models.yml"
)

# Casper id -> Fireworks model id (from the pricing-page link URLs)
CASPER_TO_FIREWORKS = {
    "ember-1": "ember-1",
    "glm-5.3": "glm-5p3",
    "glm-5.3-flash": "glm-5p3-flash",
    "kimi-k3": "kimi-k3",
    "kimi-k3p1-pro": "kimi-k3p1-pro",
    "minimax-m3": "minimax-m3",
    "qwen3.8-max": "qwen3p8-max",
}
# Catalog ids deliberately not exposed for coding use (policy: no DeepSeek for
# coding). /v1/models lists the whole catalog regardless of entitlement, so
# these appear in the catalog and in discovery; the sync neither prices them
# nor adds overrides, and does not fail closed on them.
EXCLUDED_MODELS = {"deepseek-v4p1-flash", "deepseek-v4p1-flash-1017"}
# Models Casper serves unmetered (FREE in the admin catalog at
# https://casper.ditto.live/catalog). The unmetered flag lives in Casper's
# admin DB and /v1/models deliberately does not expose it, so this list is
# maintained by hand. Fireworks pricing must NOT be applied to these: Casper
# bills nothing for them regardless of the upstream rate.
FREE_MODELS = {"auto", "dittoaicoder", "ditto-support"}
# Hand-maintained prices (input, output, cacheRead per 1M tokens) for models the
# Fireworks pricing page does not list at Standard rates it can be parsed from.
MANUAL_PRICES = {
    # Not listed on Fireworks' pricing page; rate supplied by Ditto (2026-11-16).
    "minimax-m3p1-flash": ("0.15", "0.60", "0.01"),
    # Fireworks lists only an "Ultramarine 1 Flash (US)" variant row; keeping the
    # hand-entered Ditto rate instead of the variant's ($0.15/$0.50/$0.03), which
    # disagrees with the amount actually billed, per user decision 2026-11-16.
    "ultramarine-1-flash-us": ("0.23", "0.75", "0.04"),
}

HEADER = "| Model | Standard | Priority |"
ROW = re.compile(
    r"^\| \[(?P<name>[^\]]+)\]\(https://app\.fireworks\.ai/models/fireworks/(?P<id>[^)]+)\)"
    r" \| \\\$(?P<input>[0-9.]+) / \\\$(?P<cached>[0-9.]+) / \\\$(?P<output>[0-9.]+) \|",
    re.MULTILINE,
)
VARIANT = re.compile(r"\(US\)|Fast|Ultra-fast", re.IGNORECASE)
Prices = dict[str, dict[str, str]]
Names = dict[str, str]


def parse_fireworks_prices(page: str) -> tuple[Prices, Names]:
    """Parse Standard rates as (input, output, cached) strings keyed by Fireworks id.

    The first occurrence of a link id wins: variant rows ((US), Fast, Ultra-fast)
    repeat the same link id at non-Standard rates, so they are skipped.
    """
    if HEADER not in page:
        sys.exit(f"error: pricing table header changed on {FIREWORKS_PRICING_URL}")
    prices: Prices = {}
    names: Names = {}
    for match in ROW.finditer(page):
        model_id = match["id"].strip()
        if model_id not in prices and not VARIANT.search(match["name"]):
            prices[model_id] = {
                "input": match["input"],
                "output": match["output"],
                "cached": match["cached"],
            }
            names[model_id] = match["name"].strip()
    if not prices:
        sys.exit(f"error: no prices parsed from {FIREWORKS_PRICING_URL}")
    return prices, names


def fetch_fireworks_prices() -> tuple[Prices, Names]:
    try:
        with urllib.request.urlopen(FIREWORKS_PRICING_URL, timeout=30) as response:
            page = response.read().decode("utf-8")
    except (urllib.error.URLError, TimeoutError) as err:
        sys.exit(f"error: could not fetch {FIREWORKS_PRICING_URL}: {err}")
    return parse_fireworks_prices(page)


def fetch_casper_catalog() -> list[dict]:
    key = os.environ.get("CASPER_API_KEY")
    if not key:
        sys.exit("error: CASPER_API_KEY is not set")
    request = urllib.request.Request(
        CASPER_URL, headers={"Authorization": f"Bearer {key}"}
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = json.load(response)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as err:
        sys.exit(f"error: could not fetch {CASPER_URL}: {err}")
    return payload.get("data", [])


Cost = tuple[str, str, str]  # input, output, cacheRead per 1M tokens


def price_for(casper_id: str, prices: Prices) -> Cost | None:
    """Price a catalog id or return None if it is deliberately unpriced (excluded)."""
    if casper_id in EXCLUDED_MODELS:
        return None
    if casper_id in FREE_MODELS:
        return ("0", "0", "0")
    if casper_id in MANUAL_PRICES:
        return MANUAL_PRICES[casper_id]
    model_id = CASPER_TO_FIREWORKS.get(casper_id)
    if model_id is not None:
        price = prices.get(model_id)
        if price is None:
            sys.exit(
                f"error: {casper_id} maps to Fireworks {model_id} "
                f"but that model is not on the pricing page"
            )
        return (price["input"], price["output"], price["cached"])
    sys.exit(
        f"error: {casper_id} is not in EXCLUDED_MODELS, FREE_MODELS, MANUAL_PRICES, "
        f"or CASPER_TO_FIREWORKS; classify it in the script"
    )


OVERRIDE = re.compile(
    r"^ {6}(\S+?): *(\S.*)?$"
)  # 6-space-indented key under modelOverrides
EFFORTS = re.compile(r"^([ \t]*)efforts: \[([^\]]*)\]")
COST = re.compile(r"^([ \t]*)cost: \{.*\}[ \t]*")
DEFAULT_LEVEL = re.compile(r"^([ \t]*)defaultLevel: (\S+)")


def merge(
    lines: list[str], catalog: list[dict], prices: Prices, names: Names
) -> tuple[list[str], list[str]]:
    """Merge catalog costs into YAML lines; returns (new lines, changed ids).

    Line-oriented: rewrites only `cost:` and `efforts:` lines inside
    modelOverrides blocks and removes stale blocks whole. Everything else is
    byte-identical.
    """
    catalog_ids: list[str] = []
    efforts_by_id: dict[str, list[str]] = {}
    for entry in catalog:
        cid = entry["id"]
        if cid not in catalog_ids:
            catalog_ids.append(cid)
            efforts = [
                e for e in entry.get("supported_reasoning_efforts") or [] if e != "none"
            ]
            if efforts:
                efforts_by_id[cid] = efforts

    changed: list[str] = []
    seen: set[str] = set()
    out: list[str] = []
    in_overrides = False
    insert_at: int | None = None  # index in `out` just past the last override block
    i = 0
    n = len(lines)
    while i < n:
        stripped = lines[i].rstrip("\n")
        if not in_overrides and re.match(r"^ {2,6}modelOverrides:", stripped):
            in_overrides = True
            out.append(lines[i])
            i += 1
            continue
        if (
            in_overrides
            and re.match(r"^ {2,6}\S", stripped)
            and not stripped.lstrip().startswith("#")
            and not OVERRIDE.match(stripped)
        ):
            in_overrides = False  # left the modelOverrides section
            out.append(lines[i])
            i += 1
            continue
        m = OVERRIDE.match(stripped) if in_overrides else None
        if m is None or stripped.startswith("#"):
            out.append(lines[i])
            i += 1
            continue

        cid = m.group(1)
        j = i + 1
        while j < n and (
            lines[j].startswith("        ")
            or lines[j].strip() == ""
            or lines[j].lstrip().startswith("#")
        ):
            j += 1
        block = lines[i:j]
        trailing = ""
        while j < n and lines[j].strip() == "":
            trailing += lines[j]
            j += 1

        if cid in catalog_ids:
            seen.add(cid)
            priced = price_for(cid, prices)
            if priced is None:
                out.extend(block)
            else:
                cost_in, cost_out, cost_cache = priced

                def rewrite_cost(
                    bl: str, ci: str = cost_in, co: str = cost_out, cc: str = cost_cache
                ) -> str:
                    cm = COST.match(bl)
                    if not cm:
                        return bl
                    return (
                        f"{cm.group(1)}cost: {{ input: {ci}, output: {co}, "
                        f"cacheRead: {cc}, cacheWrite: 0 }}"
                    ) + bl[cm.end() :]

                new_block = [rewrite_cost(bl) for bl in block]
                efforts = efforts_by_id.get(cid)
                if efforts is not None and any(EFFORTS.match(bl) for bl in new_block):
                    level_ok = True
                    rewritten = []
                    for bl in new_block:
                        em = EFFORTS.match(bl)
                        if em:
                            rewritten.append(
                                f"{em.group(1)}efforts: [{', '.join(efforts)}]\n"
                            )
                            continue
                        dm = DEFAULT_LEVEL.match(bl)
                        if dm and dm.group(2) not in efforts:
                            level_ok = False
                            print(
                                f"warning: {cid}: defaultLevel {dm.group(2)} not in "
                                f"ladder {efforts}; left untouched",
                                file=sys.stderr,
                            )
                        rewritten.append(bl)
                    if level_ok:
                        new_block = rewritten
                    else:
                        new_block = block  # untouched: fall back to the original lines
                if new_block != block:
                    changed.append(cid)
                out.extend(new_block)
            insert_at = len(out)
            i = j
            continue

        print(f"removed stale override {cid} (not in catalog)", file=sys.stderr)
        changed.append(cid)
        insert_at = len(out)
        i = j

    # New blocks land in alphabetical position among the override keys.
    new_ids = sorted(
        entry["id"]
        for entry in catalog
        if entry["id"] not in seen
        and entry["id"] not in EXCLUDED_MODELS
        and price_for(entry["id"], prices) is not None
    )
    for cid in new_ids:
        print(
            f"warning: new model {cid}: review for thinking ladder and compat overrides",
            file=sys.stderr,
        )
        if insert_at is not None:
            out, changed = insert_block(
                out, cid, lines_of_new_block(cid, prices, names), changed
            )
    return out, changed


MARKER = re.compile(r"^ {2,6}modelOverrides:")
# Scan state for line_key across successive calls: None = before section, "END" = past it.
current_key: list[str | None] = [None]


def line_key(line: str) -> str | None:
    """A modelOverrides key line iff inside the tracked region; None otherwise."""
    stripped = line.rstrip("\n")
    if MARKER.match(stripped):
        current_key[0] = None
        return None
    if current_key[0] == "END":
        return None
    if (
        re.match(r"^ {2,6}\S", stripped)
        and not stripped.lstrip().startswith("#")
        and not OVERRIDE.match(stripped)
    ):
        current_key[0] = "END"
        return None
    m = OVERRIDE.match(stripped)
    if m and not stripped.lstrip().startswith("#"):
        return m.group(1)
    return None


def insert_block(
    out: list[str], cid: str, block_text: str, changed: list[str]
) -> tuple[list[str], list[str]]:
    block = block_text.splitlines(keepends=True)
    for idx, l in enumerate(out):
        key = line_key(l)
        if key is not None and key > cid:
            out[idx:idx] = block
            changed.append(f"+{cid}")
            print(f"appended new model block {cid}", file=sys.stderr)
            return out, changed
    out.extend(block)
    changed.append(f"+{cid}")
    print(f"appended new model block {cid}", file=sys.stderr)
    return out, changed


def lines_of_new_block(cid: str, prices: Prices, names: Names) -> str:
    cost = price_for(cid, prices)
    if cost is None:
        sys.exit(
            f"error: {cid} is deliberately unpriced and cannot get a new model block"
        )
    cost_in, cost_out, cost_cache = cost
    fw = CASPER_TO_FIREWORKS.get(cid)
    name = (names.get(fw) if fw is not None else None) or cid.replace("-", " ").title()
    return (
        f"      {cid}:\n"
        f"        name: {name}\n"
        f"        cost: {{ input: {cost_in}, output: {cost_out}, cacheRead: {cost_cache}, cacheWrite: 0 }}\n"
        f"\n"
    )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0] if __doc__ else None
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="print a diff instead of writing"
    )
    args = parser.parse_args()

    catalog = fetch_casper_catalog()
    prices, names = fetch_fireworks_prices()
    catalog_ids = [entry["id"] for entry in catalog]
    unclassified = [
        cid
        for cid in catalog_ids
        if cid not in EXCLUDED_MODELS
        and cid not in FREE_MODELS
        and cid not in MANUAL_PRICES
        and cid not in CASPER_TO_FIREWORKS
    ]
    if unclassified:
        for cid in unclassified:
            print(
                f"error: {cid} is not in EXCLUDED_MODELS, FREE_MODELS, MANUAL_PRICES, "
                f"or CASPER_TO_FIREWORKS; classify it in the script",
                file=sys.stderr,
            )
        sys.exit(1)

    original = MODELS_YML.read_text(encoding="utf-8")
    lines, changed = merge(original.splitlines(keepends=True), catalog, prices, names)
    updated = "".join(lines)

    if updated == original:
        print("Casper model catalog unchanged")
        return
    if args.dry_run:
        sys.stdout.writelines(
            difflib.unified_diff(
                original.splitlines(keepends=True),
                updated.splitlines(keepends=True),
                fromfile=str(MODELS_YML),
                tofile=str(MODELS_YML),
            )
        )
        return
    MODELS_YML.write_text(updated, encoding="utf-8")
    for model_id in changed:
        print(f"updated {model_id}")


if __name__ == "__main__":
    main()
