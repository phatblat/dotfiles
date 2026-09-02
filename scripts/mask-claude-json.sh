#!/usr/bin/env bash
#
# mask-claude-json.sh — git "clean" filter for ~/.claude.json
#
# ~/.claude.json is 129KB of Anthropic-managed state that gains new keys on
# most Claude Code releases: lastSessionFirstPrompt (verbatim user prompts),
# loggedAuthoredArtifactPaths, oauthAccount, userID, machineID,
# githubRepoPaths, and per-project session metrics, none of which belong in
# git history. The only part worth tracking is the hand-authored MCP server
# registry (top-level mcpServers, plus each project's mcpServers and MCP
# trust/context fields) that `claude mcp add-json` writes here.
#
# This filter runs when git reads the working tree into a blob (add/status/
# diff) and keeps a strict ALLOWLIST rather than a denylist: a denylist leaks
# the next new key Anthropic adds by default, an allowlist does not. It only
# rewrites what git stores — the on-disk file Claude reads is never touched,
# so Claude keeps working normally on this machine.
#
# Projects are kept only for the fields below, and dropped entirely once none
# of those fields are present, so churn from merely opening a new directory
# in Claude Code never touches the committed blob.
#
# CHECKOUT HAZARD: smudge is `cat`, so `git checkout -- .claude.json` (or a
# stash pop, or any branch switch that touches this path) replaces the live
# file with the scrubbed blob — logging Claude out and clearing project
# trust. Recovery is re-running `claude` and re-authenticating.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .claude.json filter=claude-json
#   git config filter.claude-json.clean  ~/scripts/mask-claude-json.sh
#   git config filter.claude-json.smudge cat
#   git config filter.claude-json.required true
#
set -euo pipefail

jq -S '
  def project_fields:
    {
      mcpServers,
      enabledMcpjsonServers,
      disabledMcpjsonServers,
      disabledMcpServers,
      enableAllProjectMcpServers,
      mcpContextUris,
      allowedTools
    }
    | with_entries(select(.value != null));

  {
    mcpServers: (.mcpServers // {}),
    projects: (
      (.projects // {})
      | with_entries(.value |= project_fields)
      | with_entries(select(.value != {}))
    )
  }
'
