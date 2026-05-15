#!/usr/bin/env bash
set -euo pipefail

# Run `just format` before git commit to ensure consistent formatting.
# Stages any formatting changes so they're included in the commit.

just format 2>&1

# Stage any files that formatting changed
if ! git diff --quiet; then
  git add -u
  echo '{"systemMessage":"Auto-formatted and staged changed files before commit."}'
fi
