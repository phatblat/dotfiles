#!/usr/bin/env python3
"""Sort [tools] entries alphabetically in mise config.toml.

    sort-tools.py CONFIG            # rewrite in place
    sort-tools.py --check CONFIG    # exit 1 if the [tools] block is not already sorted
"""

import argparse
import re
import sys
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "--check",
    action="store_true",
    help="exit non-zero if the [tools] block is not already sorted (no write)",
)
parser.add_argument("config", type=Path, help="path to the mise config.toml to sort")
args = parser.parse_args()

config = args.config
content = config.read_text()

# Match the [tools] block: header through to next section or EOF
pattern = r"(\[tools\]\n)(.*?)(\n\[|\Z)"
match = re.search(pattern, content, re.DOTALL)
if not match:
    sys.exit(0)

header = match.group(1)
tools_block = match.group(2)
next_section = match.group(3)

# Split into entries, keeping multi-line inline tables/arrays intact and
# dropping top-level comments/blanks.
def bracket_delta(line: str) -> int:
    delta = 0
    quote: str | None = None
    escaped = False
    for ch in line:
        if quote is not None:
            if escaped:
                escaped = False
            elif quote == '"' and ch == "\\":
                escaped = True
            elif ch == quote:
                quote = None
        elif ch == "#":
            break
        elif ch in ('"', "'"):
            quote = ch
        elif ch in ("{", "["):
            delta += 1
        elif ch in ("}", "]"):
            delta -= 1
    return delta


entries: list[str] = []
current: list[str] = []
depth = 0
for line in tools_block.strip().split("\n"):
    if depth == 0:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        current = [line]
    else:
        current.append(line)
    depth += bracket_delta(line)
    if depth <= 0:
        entries.append("\n".join(current))
        current = []
        depth = 0
if current:
    entries.append("\n".join(current))


# Sort by the raw key (including quotes) so quoted backend-qualified
# names (e.g. "npm:...", "pipx:...") group together before bare names.
def sort_key(entry: str) -> str:
    key = entry.split("=", 1)[0].strip()
    return key.lower()


sorted_entries = sorted(entries, key=sort_key)

# Rebuild: sorted tools block + everything after it
new_tools = header + "\n".join(sorted_entries) + "\n"
new_content = (
    content[: match.start()] + new_tools + content[match.end() - len(next_section) :]
)

if args.check:
    if content != new_content:
        print(
            f"{config} [tools] is not sorted (run: just format)", file=sys.stderr
        )
        sys.exit(1)
    sys.exit(0)

if content != new_content:
    config.write_text(new_content)
