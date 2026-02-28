#!/usr/bin/env python3
"""Sort [tools] entries alphabetically in mise config.toml."""

import re
import sys
from pathlib import Path

config = Path.home() / ".config" / "mise" / "config.toml"
content = config.read_text()

# Match the [tools] block: header through to next section or EOF
pattern = r"(\[tools\]\n)(.*?)(\n\[|\Z)"
match = re.search(pattern, content, re.DOTALL)
if not match:
    sys.exit(0)

header = match.group(1)
tools_block = match.group(2)
next_section = match.group(3)

# Split into lines, separate comments/blanks from tool entries
lines = tools_block.strip().split("\n")
tool_lines = [
    line for line in lines if line.strip() and not line.strip().startswith("#")
]


# Sort by the raw key (including quotes) so quoted backend-qualified
# names (e.g. "npm:...", "pipx:...") group together before bare names.
def sort_key(line):
    key = line.split("=")[0].strip()
    return key.lower()


sorted_lines = sorted(tool_lines, key=sort_key)

# Rebuild: sorted tools block + everything after it
new_tools = header + "\n".join(sorted_lines) + "\n"
new_content = (
    content[: match.start()] + new_tools + content[match.end() - len(next_section) :]
)

config.write_text(new_content)
