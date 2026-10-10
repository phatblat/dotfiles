#!/usr/bin/env python3
"""Sync Subconscious per-token prices into the OMP subconscious profile.

Copyright: Ben Chatelain. MIT

Usage: sync-subconscious-models.py [--dry-run]

Subconscious has no pricing API, and omp's catalog has no subconscious provider,
so the vendor's pricing page (marked "Source of truth") is parsed and each
declared model's `cost:` line in models.yml is rewritten to match.
"""

import argparse
import difflib
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

PRICING_URL = "https://www.subconscious.dev/pricing.md"
MODELS_YML = (
    Path(__file__).resolve().parent.parent
    / ".omp/profiles/subconscious/agent/models.yml"
)
HEADER = "| Model | API model string | Cached input | Input | Output |"
ROW = re.compile(
    r"^\|[^|]*\|\s*`(?P<id>[^`]+)`\s*\|\s*\$(?P<cached>[0-9.]+)\s*\|\s*\$(?P<input>[0-9.]+)\s*\|\s*\$(?P<output>[0-9.]+)\s*\|\s*$",
    re.MULTILINE,
)
DATE = re.compile(r"rates last updated \d{4}-\d{2}-\d{2}")
MODEL_ID = re.compile(r"^\s*- id: (\S+)\s*$")
COST = re.compile(r"^([ \t]*)cost: \{.*\}[ \t]*")

Prices = dict[str, dict[str, str]]


def parse_prices(page: str) -> Prices:
    if HEADER not in page:
        sys.exit(f"error: pricing table header changed on {PRICING_URL}")
    prices: Prices = {
        match["id"]: {
            "input": match["input"],
            "output": match["output"],
            "cached": match["cached"],
        }
        for match in ROW.finditer(page)
    }
    if not prices:
        sys.exit(f"error: no prices parsed from {PRICING_URL}")
    return prices


def fetch_prices() -> Prices:
    try:
        with urllib.request.urlopen(PRICING_URL, timeout=30) as response:
            page = response.read().decode("utf-8")
    except (urllib.error.URLError, TimeoutError) as err:
        sys.exit(f"error: could not fetch {PRICING_URL}: {err}")
    return parse_prices(page)


def rewrite(lines: list[str], prices: Prices) -> tuple[list[str], list[str]]:
    """Returns the rewritten lines and the ids whose cost line changed."""
    missing: list[str] = []
    changed: list[str] = []
    declared: set[str] = set()
    current = ""
    out: list[str] = []
    for line in lines:
        id_match = MODEL_ID.match(line)
        if id_match:
            current = id_match[1]
            declared.add(current)
        cost_match = COST.match(line)
        if cost_match and current:
            price = prices.get(current)
            if price is None:
                missing.append(current)
            else:
                new = (
                    f"{cost_match[1]}cost: {{ input: {price['input']}, output: {price['output']}, "
                    f"cacheRead: {price['cached']}, cacheWrite: 0 }}{line[cost_match.end() :]}"
                )
                if new != line:
                    changed.append(current)
                    line = new
        out.append(line)
    if missing:
        for model_id in missing:
            print(f"error: {model_id} has no price on {PRICING_URL}", file=sys.stderr)
        sys.exit(1)
    for model_id in prices:
        if model_id not in declared:
            print(
                f"warning: {model_id} is priced on {PRICING_URL} but not declared in models.yml; add it by hand",
                file=sys.stderr,
            )
    return out, changed


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__.splitlines()[0] if __doc__ else None
    )
    parser.add_argument(
        "--dry-run", action="store_true", help="print a diff instead of writing"
    )
    args = parser.parse_args()

    prices = fetch_prices()
    original = MODELS_YML.read_text(encoding="utf-8")
    lines, changed = rewrite(original.splitlines(keepends=True), prices)
    updated = "".join(lines)
    if changed:
        today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        updated = DATE.sub(f"rates last updated {today}", updated)

    if updated == original:
        print("Subconscious pricing unchanged")
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
