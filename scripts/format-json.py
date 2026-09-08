#!/usr/bin/env python3
"""Rewrite JSON files with sorted keys and 2-space indent (jq-compatible output).

One process for the whole set — per-file jq|sponge spawns cost ~100ms each under
endpoint security (SentinelOne), which made the old per-file recipe take ~30s.

    format-json.py FILE...            # rewrite in place
    format-json.py --check FILE...    # exit 1 if any file is not formatted
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit non-zero if any file is not already formatted (no write)",
    )
    parser.add_argument("paths", nargs="*", type=Path, help="JSON files to format")
    args = parser.parse_args()

    status = 0
    for path in args.paths:
        try:
            text = path.read_text()
            # jq passes empty input through untouched; do the same
            if not text.strip():
                continue
            data = json.loads(text)
        except (OSError, json.JSONDecodeError) as err:
            print(f"format-json: {path}: {err}", file=sys.stderr)
            status = 1
            continue
        formatted = (
            json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
        )
        if text == formatted:
            continue
        if args.check:
            print(f"{path} is not formatted (run: just format)", file=sys.stderr)
            status = 1
            continue
        path.write_text(formatted)
    return status


if __name__ == "__main__":
    sys.exit(main())
