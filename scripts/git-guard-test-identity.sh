#!/usr/bin/env bash
#
# git-guard-test-identity.sh — pre-commit guard, wired in hk.pkl
#
# Never commit a leaked test identity in the tracked git config. The quickstart
# publish test suite writes "Test Suite <test-suite@example.com>" via
# `git config --global`; if its HOME isolation is bypassed (XDG_CONFIG_HOME),
# that lands in ~/.config/git/config and would be committed here. A staged
# ~/.gitconfig is the same leak, and Git reads that file after the XDG config
# so its user.name / user.email win.
#
# Deliberately no `pipefail`: `grep -q` exits on first match and `git show` then
# dies of SIGPIPE, which pipefail would report as "no match".

set -eu

cd "$(git rev-parse --show-toplevel)"

reject_test_identity() {
    local cfg="$1"
    if git show ":$cfg" | grep -qE 'Test Suite|test-suite@example\.com'; then
        echo "pre-commit: $cfg contains the test identity (Test Suite / test-suite@example.com)" >&2
        echo "pre-commit: strip those lines or run: git checkout -- $cfg" >&2
        exit 1
    fi
}

cfg=.config/git/config
if git diff --cached --name-only -- "$cfg" | grep -q .; then
    reject_test_identity "$cfg"
fi

# A staged deletion has no index blob. `git show :.gitconfig` is what made
# the old loop fail on every commit, so only scan adds and modifications.
if git diff --cached --name-only --diff-filter=AM -- .gitconfig | grep -q .; then
    reject_test_identity .gitconfig
fi
