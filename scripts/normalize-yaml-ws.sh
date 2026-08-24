#!/usr/bin/env bash
#
# normalize-yaml-ws.sh — git "clean" filter for agent-written YAML config
#
# Copyright: Ben Chatelain. MIT
#
# OMP rewrites ~/.omp/agent/config.yml at runtime whenever a setting changes,
# and its YAML emitter writes a trailing space after keys that introduce a
# nested block ("tools: ", "  approval: "). That is the only way its output
# deviates from this repo's formatting rules: across 12 historical committed
# versions, `yamllint` reported trailing-spaces and nothing else, and
# `prettier --check` reported them all clean.
#
# Left alone, the churn cycle is: OMP rewrites the file -> the trailing spaces
# are committed -> someone later runs `just format` -> a whitespace-only diff
# lands on top. That buries real setting changes in review noise, which is
# exactly what the formatting policy in AGENTS.md prohibits.
#
# A post-write hook cannot fix this without racing OMP's own writer, and OMP
# exposes no hook surface anyway. Normalizing at the git boundary instead is
# race-free: it runs when git reads the working tree into a blob (add/status/
# diff), so the committed content is always normalized no matter which tool
# wrote the file or whether anyone remembered to run `just format`. The on-disk
# file OMP reads is never touched.
#
# Deliberately narrow. This strips trailing horizontal whitespace and
# guarantees a final newline. It does not reformat, reorder, or mask values —
# a real setting change still shows up as a real diff. Both operations are
# idempotent, so re-running the filter over its own output is a no-op.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .omp/agent/config.yml filter=yaml-normalize
#   git config filter.yaml-normalize.clean  ~/scripts/normalize-yaml-ws.sh
#   git config filter.yaml-normalize.smudge cat
#   git config filter.yaml-normalize.required true
#
set -euo pipefail

# awk, not sed: BSD sed does not terminate a final line that arrived without a
# newline, and `.editorconfig` requires one. awk's `print` always emits ORS.
awk '{ sub(/[[:space:]]+$/, ""); print }'
