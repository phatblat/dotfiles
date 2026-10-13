#!/usr/bin/env bash
#
# mask-claude-desktop.sh — git "clean" filter for
# ~/Library/Application Support/Claude/claude_desktop_config.json
#
# Claude Desktop rewrites UI state into this file on nearly every launch:
# preferences.epitaxyPrefs (pane layout, last session IDs, list filters,
# notice-seen flags), preferences.sidebarMode (the sidebar tab last viewed),
# and one-shot internal flags (*Latched, floatingAtollActive,
# coworkLegacyRootGrantsPruned, coworkOnboardingResumeStep,
# launchPreviewPersistedWorkspaces, launchPreviewSessionScopedSessions).
# Those keys produced most of this file's commit history while real
# settings (coworkBrowserToolsEnabled, bypassPermissionsGateByAccount,
# keepAwakeEnabled, ...) changed only occasionally.
#
# This filter runs when git reads the working tree into a blob (add/status/
# diff) and deletes those keys, a DENYLIST: real preference toggles stay
# tracked and reviewable, and a brand-new internal key surfaces once for a
# decision about adding it here. Key order is left as the app writes it (no
# -S). It only rewrites what git stores; the on-disk file Claude Desktop
# reads is never touched.
#
# CHECKOUT HAZARD: smudge is `cat`, so `git checkout -- <this file>` (or a
# stash pop, or a branch switch that touches this path) replaces the live
# file with the scrubbed blob. That loses only the stripped UI state above;
# every real preference is in the blob and survives.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  "Library/Application Support/Claude/claude_desktop_config.json" filter=claude-desktop-config
#   git config filter.claude-desktop-config.clean  ~/scripts/mask-claude-desktop.sh
#   git config filter.claude-desktop-config.smudge cat
#   git config filter.claude-desktop-config.required true
#
set -euo pipefail

jq '
  if (.preferences | type) == "object" then
    .preferences |= with_entries(select(
      (.key | IN("epitaxyPrefs", "sidebarMode", "floatingAtollActive",
                 "coworkLegacyRootGrantsPruned", "coworkOnboardingResumeStep",
                 "launchPreviewPersistedWorkspaces",
                 "launchPreviewSessionScopedSessions")
         or endswith("Latched")) | not
    ))
  else
    .
  end
'
