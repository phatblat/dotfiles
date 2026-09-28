#!/usr/bin/env bash
#
# gitleaks-tree.sh — scan the current HEAD tree for secrets.
#
# `git archive` includes only tracked content, so the huge untracked/ignored
# directories under this repo's $HOME root (OrbStack, Library, node_modules,
# ...) are never touched, and each currently-present line is scanned exactly
# once instead of once per historical commit that introduced it (`gitleaks
# git`'s default full-log scan). `gitleaks dir` doesn't honor .gitignore on
# its own, which is why this archives to a clean tree first rather than
# pointing it at the working copy directly.
#
# The gitleaks-protect step already gates the staged diff on every commit;
# this step exists to catch secrets that reached HEAD another way (a
# force-added file, --no-verify, a commit made before gitleaks was wired up).

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

git -C "$repo_root" archive HEAD | tar -x -C "$tmpdir"
cd "$tmpdir"
gitleaks dir . --config "$repo_root/.gitleaks.toml" --redact --verbose --no-banner
