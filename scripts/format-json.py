#!/usr/bin/env python3
"""Rewrite JSON files with sorted keys and 2-space indent (jq-compatible output).

Reads NUL-separated file paths from stdin. One process for the whole set —
per-file jq|sponge spawns cost ~100ms each under endpoint security (SentinelOne),
which made `just format-json` take ~30s.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    status = 0
    for raw in sys.stdin.buffer.read().split(b"\0"):
        if not raw:
            continue
        path = Path(raw.decode())
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
        path.write_text(
            json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
        )
    return status


if __name__ == "__main__":
    sys.exit(main())
