#!/usr/bin/env bash
# Report whether a path belongs to the dotfiles checkout.
# Exit 0 only when the caller's canonical git common dir matches this script's.
#
# Copyright: Ben Chatelain. MIT.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script_dir="$(realpath "$script_dir")"

# Root is the dotfiles checkout that contains this script under scripts/.
repo_root="$(realpath "$script_dir/..")"

check_dir="${1:-$PWD}"

cand_common_dir="$(git -C "$check_dir" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"
[ -n "$cand_common_dir" ] || exit 1
repo_common_dir="$(git -C "$repo_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || printf '')"
[ -n "$repo_common_dir" ] || exit 1
[ "$cand_common_dir" = "$repo_common_dir" ] || exit 1
