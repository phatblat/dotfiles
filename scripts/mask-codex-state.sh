#!/usr/bin/env bash
#
# mask-codex-state.sh — git "clean" filter for ~/.codex/*.toml config files
#
# Codex rewrites machine-managed state into config.toml and the per-profile
# *.config.toml files on nearly every launch (marketplace sync timestamps/revisions,
# hook trust hashes, and the bundled browser plugin's pinned app version/client
# hash). Tracking those files verbatim produces constant diff churn and
# cross-machine merge conflicts.
#
# This filter runs when git reads the working tree into a blob (add/status/diff)
# and normalizes the volatile VALUES to fixed sentinels, so the committed content
# is stable across launches and machines. Sentinels are valid values of the right
# type (epoch timestamp, all-zero SHA/hash) so a fresh checkout parses cleanly.
#
# Hook trust hashes are the one value that must not be lost: Codex skips a hook
# whose hash is unrecognised until it is re-trusted in /hooks, and a checkout
# writes the sentinel blob back over the real hashes. So before masking, this
# filter records the real per-hook hashes in a machine-local cache
# (restore-codex-trust.sh, the smudge filter, reads it back on checkout). The
# cache never enters the repo: a trust grant is a per-machine decision.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .codex/config.toml filter=codex-config
#                    .codex/*.config.toml filter=codex-config
#   git config filter.codex-config.clean  ~/scripts/mask-codex-state.sh
#   git config filter.codex-config.smudge ~/scripts/restore-codex-trust.sh
#   git config filter.codex-config.required true
#
set -euo pipefail

cache="${CODEX_HOOK_TRUST_CACHE:-${XDG_STATE_HOME:-$HOME/.local/state}/codex-hook-trust.tsv}"
input="$(mktemp)"
newcache=""
trap 'rm -f "$input" ${newcache:+"$newcache"}' EXIT
cat > "$input"

# Capture real hashes. Best effort: a failure here must never fail the filter,
# or `git status` would break. But a failed capture must also never touch the
# cache: `capture || true` suspends `set -e` in here, so every failure is
# checked and returned explicitly, leaving the existing cache as it was.
#
# Concurrent cleans (two files staged together) each read-merge-write, so one
# can lose the other's new key. That costs one /hooks re-trust, not a wrong
# hash, so it is accepted rather than guarded with a lock macOS lacks (flock).
capture() {
    # An existing but unreadable cache would read as an empty map, and the
    # merge would then replace it with only this file's keys.
    if [[ -e "$cache" && ! -r "$cache" ]]; then
        return 1
    fi
    mkdir -p "$(dirname "$cache")" || return 1
    newcache="$(mktemp "$(dirname "$cache")/.codex-hook-trust.XXXXXX")" || return 1
    awk -v cache="$cache" '
        BEGIN {
            while ((getline line < cache) > 0) {
                split(line, a, "\t")
                old[a[1]] = a[2]
            }
        }
        /^\[/ {
            h = ($0 ~ /^\[hooks\.state\./) ? $0 : ""
            next
        }
        /^trusted_hash = "/ && h != "" {
            if ($0 !~ /sha256:0+"$/) old[h] = $0
            h = ""
        }
        END {
            # Merge, never prune: the cache is shared by config.toml and every
            # *.config.toml, whose hook key sets differ, so a key this file does
            # not mention may belong to another one. A stale key is harmless
            # because restore-codex-trust.sh only matches exact keys.
            for (k in old) if (old[k] != "") printf "%s\t%s\n", k, old[k]
        }
    ' "$input" | LC_ALL=C sort > "$newcache" || return 1
    # Only touch the cache when it changed. $newcache lives in the cache's own
    # directory, so this mv is a same-filesystem rename and a concurrent smudge
    # never reads a half-written cache.
    if ! cmp -s "$newcache" "$cache" 2>/dev/null; then
        mv -f "$newcache" "$cache" || return 1
    fi
}
capture || true

sed -E \
    -e 's|^(last_updated = )".*"|\1"1970-01-01T00:00:00Z"|' \
    -e 's|^(last_revision = )".*"|\1"0000000000000000000000000000000000000000"|' \
    -e 's|^(trusted_hash = )".*"|\1"sha256:0000000000000000000000000000000000000000000000000000000000000000"|' \
    -e 's|^(BROWSER_USE_CODEX_APP_VERSION = )".*"|\1"0.0.0"|' \
    -e 's|^(NODE_REPL_TRUSTED_BROWSER_CLIENT_SHA256S = )".*"|\1"0000000000000000000000000000000000000000000000000000000000000000"|' \
    -e 's|/private/var/folders/[^/]+/[^/]+/T/AppTranslocation/[^/]+/d/ChatGPT\.app|/Applications/ChatGPT.app|g' \
    "$input"
