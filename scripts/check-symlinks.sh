#!/usr/bin/env bash
#
# check-symlinks.sh — fail on tracked symlinks whose absolute target points back
# at tracked repo content.
#
# Absolute targets resolve into the real $HOME from inside a worktree, so they
# return whichever branch is checked out there instead of this tree's own
# content. Symlinks aimed outside the repo (system binaries, untracked app
# state) are fine.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

offenders=()
for path in "$@"; do
    [ -L "$path" ] || continue
    target=$(readlink "$path")
    case "$target" in "$HOME"/*) ;; *) continue ;; esac
    rel="${target#"$HOME"/}"
    if git ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
        offenders+=("$path -> $target")
        continue
    fi
    # The target may itself pass through a tracked symlink (e.g. a directory
    # alias), so also check what it ultimately resolves to. A dangling target
    # is not tracked either way.
    real=$(realpath "$target" 2>/dev/null || true)
    if [ -n "$real" ] && [ "${real#"$HOME"/}" != "$real" ]; then
        if git ls-files --error-unmatch "${real#"$HOME"/}" >/dev/null 2>&1; then
            offenders+=("$path -> $target")
        fi
    fi
done

if ((${#offenders[@]})); then
    echo "Tracked symlinks with absolute targets pointing at tracked repo content:" >&2
    printf '  %s\n' "${offenders[@]}" >&2
    echo "Convert to a relative target so worktrees resolve this repo's own content." >&2
    exit 1
fi
