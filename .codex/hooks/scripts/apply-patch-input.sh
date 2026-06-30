#!/usr/bin/env bash
# Shared parsing helpers for Codex apply_patch hook input.
#
# Copyright 2026 Ben Chatelain
# SPDX-License-Identifier: Apache-2.0

apply_patch_command() {
    jq -r '.tool_input.command // empty'
}

apply_patch_all_paths() {
    apply_patch_command | awk '
        /^\*\*\* (Add|Update|Delete) File: / {
            sub(/^\*\*\* (Add|Update|Delete) File: /, "")
            if (!seen[$0]++) print
        }
        /^\*\*\* Move to: / {
            sub(/^\*\*\* Move to: /, "")
            if (!seen[$0]++) print
        }
    '
}

apply_patch_changed_paths() {
    apply_patch_command | awk '
        /^\*\*\* (Add|Update) File: / {
            sub(/^\*\*\* (Add|Update) File: /, "")
            if (!seen[$0]++) print
        }
        /^\*\*\* Move to: / {
            sub(/^\*\*\* Move to: /, "")
            if (!seen[$0]++) print
        }
    '
}

apply_patch_added_content() {
    apply_patch_command | awk '
        /^\+/ && !/^\+\+\+/ {
            print substr($0, 2)
        }
    '
}
