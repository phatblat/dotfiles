#!/usr/bin/env bash
#
# mask-antigravity.sh — git "clean" filter for
# ~/.gemini/antigravity-cli/settings.json
#
# `trustedWorkspaces` records a per-machine security decision: absolute
# workspace paths the user has explicitly approved to bypass Antigravity's
# sandbox restrictions. Committing it verbatim replicates that trust grant to
# every machine that clones this repo, auto-approving a directory that was
# only ever vetted on one machine, a privilege escalation dressed as config.
#
# This filter runs when git reads the working tree into a blob (add/status/
# diff) and strips the trustedWorkspaces field entirely, so the committed
# content never carries the grant. It only rewrites what git stores; the
# on-disk file Antigravity reads is never touched, so trust decisions made on
# this machine keep working normally.
#
# A missing trustedWorkspaces key is not an error: Antigravity treats an
# absent/empty list as "nothing trusted yet" and re-prompts on next use,
# which is the safe default for a fresh checkout on another machine.
#
# Wiring (installed by `just git-filters`, not committed to .git/config):
#   .gitattributes:  .gemini/antigravity-cli/settings.json filter=antigravity-settings
#   git config filter.antigravity-settings.clean  ~/scripts/mask-antigravity.sh
#   git config filter.antigravity-settings.smudge cat
#   git config filter.antigravity-settings.required true
#
set -euo pipefail

jq 'del(.trustedWorkspaces)'
