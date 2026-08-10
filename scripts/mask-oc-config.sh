#!/usr/bin/env bash
#
# mask-oc-config.sh — git "clean" filter for ~/.oc/config.json
#
# `oc login` writes a live OpenComputer API key into ~/.oc/config.json
# alongside non-secret metadata (api_url, login.credential_id, login.name,
# login.key_prefix — an 8-char identifying prefix, not the secret itself).
# Tracking that file verbatim would commit the live key to git history on
# every login/re-auth.
#
# This filter runs when git reads the working tree into a blob (add/status/
# diff) and strips the api_key field entirely, so the committed content never
# contains the secret. It only rewrites what git stores — the on-disk file
# `oc` reads is never touched, so `oc` keeps working normally.
#
# The stripped api_key is not needed at runtime: `oc` resolves credentials
# with precedence --api-key flag > $OPENCOMPUTER_API_KEY > config file, so
# exporting OPENCOMPUTER_API_KEY (from an untracked local env file) makes the
# config file's api_key field irrelevant even when absent.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .oc/config.json filter=oc-config
#   git config filter.oc-config.clean  ~/scripts/mask-oc-config.sh
#   git config filter.oc-config.smudge cat
#   git config filter.oc-config.required true
#
set -euo pipefail

jq 'del(.api_key)'
