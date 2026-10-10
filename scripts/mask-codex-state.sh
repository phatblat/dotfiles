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
trap 'rm -f "$input" "$input.cache"' EXIT
cat > "$input"

# Capture real hashes. Best effort: a failure here must never fail the filter,
# or `git status` would break.
capture() {
    mkdir -p "$(dirname "$cache")"
    awk -v cache="$cache" '
        BEGIN {
            while ((getline line < cache) > 0) {
                split(line, a, "\t")
                old[a[1]] = a[2]
            }
        }
        /^\[/ {
            h = ($0 ~ /^\[hooks\.state\./) ? $0 : ""
            if (h != "") seen[h] = 1
            next
        }
        /^trusted_hash = "/ && h != "" {
            if ($0 !~ /sha256:0+"$/) cur[h] = $0
            h = ""
        }
        END {
            # Entries for hooks no longer in the file are dropped.
            for (k in seen) {
                v = (k in cur) ? cur[k] : ((k in old) ? old[k] : "")
                if (v != "") printf "%s\t%s\n", k, v
            }
        }
    ' "$input" > "$input.cache"
    # Only touch the cache when it changed, and swap atomically.
    if ! cmp -s "$input.cache" "$cache" 2>/dev/null; then
        mv -f "$input.cache" "$cache"
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
