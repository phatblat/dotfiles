#!/usr/bin/env bash
#
# check-hk-version.sh — hk.pkl must pin the Pkl package for the installed hk.
#
# hk embeds the package for its own version and then evaluates hk.pkl with no
# network request; pinning any other version downloads it on every run.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

pinned=$(sed -nE 's|^amends .*/v([0-9.]+)/hk@.*|\1|p' hk.pkl)
installed=$(hk version)

if [ "$pinned" != "$installed" ]; then
    echo "hk.pkl pins hk@$pinned but the installed hk is $installed" >&2
    echo "update the amends line in hk.pkl (or the mise pin, if that is what moved)" >&2
    exit 1
fi
