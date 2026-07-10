#!/usr/bin/env bash
# Copyright 2026 Ben Chatelain
# Licensed under the Apache License, Version 2.0.

set -euo pipefail

audit_log="${CODEX_AUDIT_LOG:-${HOME}/.codex/audit.log}"
repo=$(git rev-parse --show-toplevel 2>/dev/null || printf 'no-repo')
commit=$(git rev-parse --short HEAD 2>/dev/null || printf 'no-commit')

mkdir -p "$(dirname "$audit_log")"
printf '%s CODEX_SESSION task_complete repo=%s commit=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$repo" \
    "$commit" >> "$audit_log"

printf '{}\n'
