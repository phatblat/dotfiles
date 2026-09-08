#!/usr/bin/env bash
#
# git-guard-test-identity.sh — pre-commit guard, wired in hk.pkl
#
# Never commit a leaked test identity in the tracked git config. The quickstart
# publish test suite writes "Test Suite <test-suite@example.com>" via
# `git config --global`; if its HOME isolation is bypassed (XDG_CONFIG_HOME),
# that lands in ~/.config/git/config and would be committed here.
#
# Deliberately no `pipefail`: `grep -q` exits on first match and `git show` then
# dies of SIGPIPE, which pipefail would report as "no match".

set -eu

cd "$(git rev-parse --show-toplevel)"

for cfg in .config/git/config .gitconfig; do
    git diff --cached --name-only -- "$cfg" | grep -q . || continue
    if git show ":$cfg" | grep -qE 'Test Suite|test-suite@example\.com'; then
        echo "pre-commit: $cfg contains the test identity (Test Suite / test-suite@example.com)" >&2
        echo "pre-commit: strip those lines or run: git checkout -- $cfg" >&2
        exit 1
    fi
done
