#!/usr/bin/env python3
# Find the literal `git [-C path ...] commit` target in an untrusted command string.
# Copyright: Ben Chatelain. MIT.

from __future__ import annotations

import os
import re
import shlex

_BOUNDARY_CHARS = set(";&|\n")
# Words that may precede a command without changing which repo it targets.
_PREFIX_WORDS = {"sudo", "command", "exec", "time", "then", "do", "else", "elif", "if", "while", "until", "!", "{", "("}
_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
# Global git options that take no operand.
_FLAG_OPTIONS = {
    "--no-pager",
    "--paginate",
    "-p",
    "-P",
    "--no-optional-locks",
    "--no-replace-objects",
    "--literal-pathspecs",
    "--no-literal-pathspecs",
    "--glob-pathspecs",
    "--noglob-pathspecs",
    "--icase-pathspecs",
}


def _is_dynamic(argument: str) -> bool:
    return not argument or any(mark in argument for mark in ("$", "`"))


def _resolve(base: str, argument: str) -> str | None:
    if _is_dynamic(argument):
        return None
    return os.path.abspath(os.path.join(base, os.path.expanduser(argument)))


def commit_target(command: str, cwd: str) -> str | None:
    """Find literal `git [global options] commit` at a shell command boundary.

    Newlines and `; & |` start a new command. Leading `VAR=val`, `sudo`, and
    `then`-style words are skipped, `git -c k=v`, `--no-pager` and friends are
    accepted, `-C` operands are `~`-expanded, and a preceding `cd <dir>` moves
    the directory later commands resolve against. Dynamic operands and unknown
    git options return None.
    """
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|\n")
    lexer.whitespace_split = True
    lexer.whitespace = " \t\r"
    lexer.commenters = ""
    try:
        tokens = list(lexer)
    except ValueError:
        return None
    current: str | None = cwd
    at_boundary = True
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token and set(token) <= _BOUNDARY_CHARS:
            at_boundary = True
            index += 1
            continue
        if at_boundary and (_ASSIGNMENT.match(token) or token in _PREFIX_WORDS):
            index += 1
            continue
        if at_boundary and token == "cd" and index + 1 < len(tokens):
            argument = tokens[index + 1]
            if set(argument) <= _BOUNDARY_CHARS:
                current = cwd
            else:
                current = _resolve(current, argument) if current is not None else None
                index += 1
        elif at_boundary and token == "git":
            target = current
            index += 1
            while index < len(tokens):
                option = tokens[index]
                if option == "-C":
                    if index + 1 >= len(tokens) or target is None:
                        return None
                    target = _resolve(target, tokens[index + 1])
                    if target is None:
                        return None
                    index += 2
                elif option == "-c":
                    if index + 1 >= len(tokens):
                        return None
                    index += 2
                elif option in _FLAG_OPTIONS:
                    index += 1
                else:
                    break
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
