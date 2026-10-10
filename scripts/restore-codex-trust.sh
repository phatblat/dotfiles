#!/usr/bin/env bash
#
# restore-codex-trust.sh — git "smudge" filter for ~/.codex/*.toml config files
#
# Counterpart to mask-codex-state.sh. The committed blob carries all-zero
# placeholder hook trust hashes; a plain `cat` smudge writes those over the
# real hashes on every checkout or pull, so Codex marks every hook for review
# and skips it until re-trusted in /hooks. This filter substitutes the real
# hash back for each hook that has one recorded in the machine-local cache.
#
# Safe by construction: a hash is only restored for the same
# `[hooks.state."<hooks.json>:<event>:<group>:<handler>"]` key. If hooks.json
# changed, Codex compares the restored hash against the new hook definition
# and still asks for review. A missing or unreadable cache degrades to `cat`.
#
set -uo pipefail

cache="${CODEX_HOOK_TRUST_CACHE:-${XDG_STATE_HOME:-$HOME/.local/state}/codex-hook-trust.tsv}"

if [[ ! -r "$cache" ]]; then
    exec cat
fi

awk -v cache="$cache" '
    BEGIN {
        while ((getline line < cache) > 0) {
            split(line, a, "\t")
            real[a[1]] = a[2]
        }
    }
    /^\[/ { h = ($0 ~ /^\[hooks\.state\./) ? $0 : "" }
    /^trusted_hash = "sha256:0+"$/ && h != "" && (h in real) {
        print real[h]
        next
    }
    { print }
'
