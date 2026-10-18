#!/usr/bin/env bash
#
# mask-gemini-config.sh — git "clean" filter for ~/.gemini/config/config.json
#
# Antigravity rewrites this file on its own as plugins update or sidecars
# resolve, none of which is hand-authored configuration:
#   - plugins.<name>.installedFrom.version follows whichever marketplace build
#     is installed, and moves between machines (even backwards, e.g. 1.0.0 ->
#     0.21.0), so the committed value never settles.
#   - sidecars is per-project runtime state (project IDs, resolved permission
#     grants) that appears after a sidecar first runs.
#
# This filter runs when git reads the working tree into a blob (add/status/
# diff). It normalizes every installedFrom.version to the empty string and
# drops the sidecars key, so the committed content only changes when real
# configuration does (plugin enablement, installedFrom.id/marketplace, user
# settings). It only rewrites what git stores; the on-disk file Antigravity
# reads is never touched.
#
# Sentinel vs. deletion: version is non-secret and keeps its string type so
# the committed file still parses on a fresh checkout. sidecars is deleted
# outright; it was never part of the tracked file and Antigravity recreates it
# when a sidecar runs. A missing plugins key is left alone.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .gemini/config/config.json filter=gemini-config
#   git config filter.gemini-config.clean  ~/scripts/mask-gemini-config.sh
#   git config filter.gemini-config.smudge cat
#   git config filter.gemini-config.required true
#
set -euo pipefail

jq '
  del(.sidecars)
  | if (.plugins | type) == "object" then
      .plugins |= with_entries(
        if (.value | type) == "object"
           and ((.value.installedFrom? | type) == "object")
           and (.value.installedFrom | has("version"))
        then .value.installedFrom.version = ""
        else .
        end
      )
    else .
    end
'
