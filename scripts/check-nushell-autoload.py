#!/usr/bin/env python3
"""Fail when a nushell autoload file executes code at load time.

Every .nu file in ~/.config/nushell/autoload is sourced by each interactive
nushell session, so a top-level statement runs at shell startup against
whatever directory the shell opened in. Autoload files may only declare:
commands, aliases, constants, modules, environment variables.

    check-nushell-autoload.py FILE...   # exit 1 if any file has top-level code
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Keywords that only declare. Anything else at column 0 runs at startup.
# `let`/`mut` are deliberately absent: their right-hand side runs too.
DECLARATIONS = frozenset(
    {
        "alias",
        "const",
        "def",
        "export",
        "export-env",
        "extern",
        "hide",
        "hide-env",
        "module",
        "source",
        "source-env",
        "use",
    }
)


def offenders(text: str) -> list[tuple[int, str, str]]:
    """Return (line, first token, text) for every top-level statement."""
    found: list[tuple[int, str, str]] = []
    depth = 0
    quote: str | None = None

    for lineno, line in enumerate(text.split("\n"), 1):
        # Only a line starting at column 0, outside any block or string, can
        # begin a top-level statement.
        if depth == 0 and quote is None and line[:1] not in ("", " ", "\t"):
            token = line.split(maxsplit=1)[0]
            if (
                not token.startswith("#")
                and not token.startswith("$env.")
                and token not in DECLARATIONS
            ):
                found.append((lineno, token, line.rstrip()))

        index = 0
        while index < len(line):
            char = line[index]
            if quote is not None:
                if quote == '"' and char == "\\":
                    index += 2
                    continue
                if char == quote:
                    quote = None
            elif char == "#":
                break  # rest of the line is a comment
            elif char in "\"'`":
                quote = char
            elif char in "{([":
                depth += 1
            elif char in "})]":
                depth -= 1
            index += 1
        # An unterminated quote carries into the next line: a multi-line string.

    return found


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path, help="nushell autoload files")
    args = parser.parse_args()

    status = 0
    for path in args.paths:
        try:
            text = path.read_text()
        except OSError as err:
            print(f"check-nushell-autoload: {path}: {err}", file=sys.stderr)
            status = 1
            continue
        for lineno, token, line in offenders(text):
            print(
                f"{path}:{lineno}: `{token}` runs at shell startup: {line}",
                file=sys.stderr,
            )
            status = 1
    if status:
        print(
            "autoload files must only declare; wrap code in `export def`",
            file=sys.stderr,
        )
    return status


if __name__ == "__main__":
    sys.exit(main())
