#!/usr/bin/env python3
# Find the literal `git [-C path ...] commit` target in an untrusted command string.
# Copyright: Ben Chatelain. MIT.

from __future__ import annotations

import os
import shlex


def commit_target(command: str, cwd: str) -> str | None:
    """Find literal `git [-C path ...] commit` at a shell command boundary."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|")
    lexer.whitespace_split = True
    lexer.commenters = ""
    try:
        tokens = list(lexer)
    except ValueError:
        return None
    at_boundary = True
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token and set(token) <= set(";&|"):
            at_boundary = True
            index += 1
            continue
        if at_boundary and token == "git":
            target = cwd
            index += 1
            while index < len(tokens) and tokens[index] == "-C":
                if index + 1 >= len(tokens):  # missing git -C operand
                    return None
                argument = tokens[index + 1]
                if not argument or any(mark in argument for mark in ("$", "`")):
                    return None
                target = os.path.abspath(os.path.join(target, argument))
                index += 2
            if index < len(tokens) and tokens[index] == "commit":
                return target
        at_boundary = False
        index += 1
    return None


if __name__ == "__main__":
    import sys

    result = commit_target(sys.argv[1], sys.argv[2])
    if result is not None:
        print(result)
