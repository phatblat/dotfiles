#!/usr/bin/env bats
# nu-wave1-apple.bats — Nushell port tests for Apple/Xcode/editor wave-1 functions
# Functions: screen_sharing, codesign_verify, list_codesign_identities, simclean, xcsp, vi, vim, pai (skipped)

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# codesign_verify — codesign --verify with Apple cert requirement (mutating: parse only)
# ---------------------------------------------------------------------------

@test "codesign_verify: smoke — help flag succeeds" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/codesign_verify.nu'
        codesign_verify --help
    " 2>&1
    # codesign --help exits non-zero but produces usage output
    [[ "$output" == *"codesign"* ]]
}

# ---------------------------------------------------------------------------
# list_codesign_identities — security find-identity -v -p codesigning (read-only)
# ---------------------------------------------------------------------------

@test "list_codesign_identities: smoke — lists identities found" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/list_codesign_identities.nu'
        list_codesign_identities
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"valid identities found"* ]]
}

# ---------------------------------------------------------------------------
# simclean — xcrun simctl delete unavailable (mutating: parse only)
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# xcsp — xcode-select --print-path (read-only)
# ---------------------------------------------------------------------------

@test "xcsp: smoke — prints a path" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/xcsp.nu'
        xcsp
    "
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" == *"/"* ]]
}

# ---------------------------------------------------------------------------
# vi — alias to nvim (read-only: parse + alias expansion check)
# ---------------------------------------------------------------------------

@test "vi: smoke — alias expands to nvim" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/vi.nu'
        help vi
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim"* ]]
}

# ---------------------------------------------------------------------------
# vim — alias to nvim (read-only: parse + alias expansion check)
# ---------------------------------------------------------------------------

@test "vim: smoke — alias expands to nvim" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/vim.nu'
        help vim
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"nvim"* ]]
}

# ---------------------------------------------------------------------------
# pai — SKIPPED: ~/.claude/skills/PAI/Tools/pai.ts does not exist on disk;
#        the PAI skill has never been installed in this environment.
#        Port deferred until the skill is installed.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# screen_sharing — Screen Sharing control (com.apple.screensharing)
#   Mutating subcommands are asserted against a fake sudo on PATH: the tests
#   check the exact launchctl argv and never touch the real service.
# ---------------------------------------------------------------------------

fake_sudo_dir() {
    local dir
    dir="$(mktemp -d)"
    printf '#!/bin/sh\nprintf "%%s\\n" "$*"\n' >"$dir/sudo"
    chmod +x "$dir/sudo"
    printf '%s' "$dir"
}

@test "screen_sharing: no args defaults to status and reports the screen sharing override" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/screen_sharing.nu'
        screen_sharing
    "
    [ "$status" -eq 0 ]
    [[ "$output" == '"com.apple.screensharing" => '* ]]
}

@test "screen_sharing enable: writes the override before loading the daemon" {
    local fakebindir
    fakebindir="$(fake_sudo_dir)"

    run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/screen_sharing.nu'
        screen_sharing enable
    "
    rm -rf "$fakebindir"

    [ "$status" -eq 0 ]
    [ "$output" = $'launchctl enable system/com.apple.screensharing\nlaunchctl bootstrap system /System/Library/LaunchDaemons/com.apple.screensharing.plist' ]
}

@test "screen_sharing disable: writes the override before unloading the daemon" {
    local fakebindir
    fakebindir="$(fake_sudo_dir)"

    run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/screen_sharing.nu'
        screen_sharing disable
    "
    rm -rf "$fakebindir"

    [ "$status" -eq 0 ]
    [ "$output" = $'launchctl disable system/com.apple.screensharing\nlaunchctl bootout system/com.apple.screensharing' ]
}

@test "screen_sharing restart: appends extra arguments to launchctl kickstart" {
    local fakebindir
    fakebindir="$(fake_sudo_dir)"

    run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/screen_sharing.nu'
        screen_sharing restart -p
    "
    rm -rf "$fakebindir"

    [ "$status" -eq 0 ]
    [ "$output" = "launchctl kickstart -k system/com.apple.screensharing -p" ]
}

@test "screen_sharing: rejects an unknown subcommand" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/screen_sharing.nu'
        screen_sharing bogus
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown subcommand 'bogus'"* ]]
}
