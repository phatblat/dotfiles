#!/usr/bin/env bash
#
# mask-codex-state.sh — git "clean" filter for ~/.codex/config.toml
#
# Codex rewrites machine-managed state into config.toml on nearly every launch
# (marketplace sync timestamps/revisions, hook trust hashes). Tracking that file
# verbatim produces constant diff churn and cross-machine merge conflicts.
#
# This filter runs when git reads the working tree into a blob (add/status/diff)
# and normalizes the volatile VALUES to fixed sentinels, so the committed content
# is stable across launches and machines. It only rewrites what git stores — the
# on-disk file Codex reads is never touched, so Codex keeps its real state.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .codex/config.toml filter=codex-config
#   git config filter.codex-config.clean  ~/scripts/mask-codex-state.sh
#   git config filter.codex-config.smudge cat
#   git config filter.codex-config.required true
#
# Sentinels are valid values of the right type (epoch timestamp, all-zero SHA/hash)
# so a fresh checkout parses cleanly; Codex regenerates real values on next launch.
#
set -euo pipefail

sed -E \
    -e 's|^(last_updated = )".*"|\1"1970-01-01T00:00:00Z"|' \
    -e 's|^(last_revision = )".*"|\1"0000000000000000000000000000000000000000"|' \
    -e 's|^(trusted_hash = )".*"|\1"sha256:0000000000000000000000000000000000000000000000000000000000000000"|'
