"""Lenient loader for Codex ``config.toml``.

Codex accepts a TOML 1.1-flavored dialect that stdlib ``tomllib`` (TOML 1.0)
rejects: multi-line inline tables and trailing commas inside inline tables.
The dotfiles sorter (``scripts/sort-codex-config.py``) deliberately preserves
that dialect byte-for-byte, so tests must parse the config the same way.

``load`` first tries strict ``tomllib``; on failure it collapses multi-line
brace/bracket regions onto a single line and drops trailing commas before a
close token, then re-parses. The scan is string-aware, so braces inside quoted
values (e.g. ``"${DD_API_KEY}"``) never affect nesting depth.

Copyright: Ben Chatelain. MIT.
"""

from __future__ import annotations

import tomllib
from pathlib import Path


def _normalize(text: str) -> str:
    out: list[str] = []
    depth = 0
    quote: str | None = None
    i = 0
    n = len(text)

    def strip_trailing_comma() -> None:
        while out and out[-1] in " \t":
            out.pop()
        if out and out[-1] == ",":
            out.pop()

    while i < n:
        ch = text[i]

        if quote is not None:
            if quote in ('"""', "'''"):
                if text.startswith(quote, i):
                    out.append(quote)
                    i += 3
                    quote = None
                else:
                    out.append(ch)
                    i += 1
                continue
            if quote == '"' and ch == "\\":
                out.append(text[i : i + 2])
                i += 2
                continue
            if ch == quote:
                quote = None
            out.append(ch)
            i += 1
            continue

        if text.startswith('"""', i) or text.startswith("'''", i):
            quote = text[i : i + 3]
            out.append(quote)
            i += 3
            continue
        if ch in ('"', "'"):
            quote = ch
            out.append(ch)
            i += 1
            continue
        if ch == "#":  # comment — drop to end of line (tomllib does not need it)
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if ch in "{[":
            depth += 1
            out.append(ch)
            i += 1
            continue
        if ch in "}]":
            strip_trailing_comma()
            depth = max(0, depth - 1)
            out.append(ch)
            i += 1
            continue
        if ch == "\n" and depth > 0:
            out.append(" ")
            i += 1
            continue

        out.append(ch)
        i += 1

    return "".join(out)


def load(path: str | Path) -> dict:
    text = Path(path).read_text()
    try:
        return tomllib.loads(text)
    except tomllib.TOMLDecodeError:
        return tomllib.loads(_normalize(text))
