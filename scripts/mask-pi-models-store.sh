#!/usr/bin/env bash
#
# mask-pi-models-store.sh — git "clean" filter for ~/.pi/agent/models-store.json
#
# The Pi agent rewrites ~/.pi/agent/models-store.json on nearly every model-list
# refresh: each provider object's checkedAt/etag/lastModified cache-validator
# fields change even when the model catalog itself is unchanged. Tracking those
# fields verbatim produces constant diff churn unrelated to real model data.
#
# This filter runs when git reads the working tree into a blob (add/status/diff)
# and normalizes the volatile VALUES to fixed sentinels, so the committed content
# is stable across refreshes and machines. It only rewrites what git stores — the
# on-disk file Pi reads is never touched, so Pi keeps its real cache state.
#
# Sentinels preserve the source JSON type (numeric epoch -> 0, string ETag -> "")
# so a fresh checkout still parses cleanly; Pi repopulates real values on next
# refresh. walk() visits every nested object (each provider's model entries),
# not just the top level, so the same three keys are masked wherever they occur.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .pi/agent/models-store.json filter=pi-models-store
#   git config filter.pi-models-store.clean  ~/scripts/mask-pi-models-store.sh
#   git config filter.pi-models-store.smudge cat
#   git config filter.pi-models-store.required true
#
set -euo pipefail

jq '
  walk(
    if type == "object" then
      with_entries(
        if .key == "checkedAt" or .key == "lastModified" then
          .value = 0
        elif .key == "etag" then
          .value = ""
        else
          .
        end
      )
    else
      .
    end
  )
'
