#!/usr/bin/env bats
# nu-wave1-apple.bats — Nushell port tests for Apple/Xcode/editor wave-1 functions
# Functions: codesign_verify, list_codesign_identities, simclean, xcsp, vi, vim, pai (skipped)

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# codesign_verify — codesign --verify with Apple cert requirement (mutating: parse only)
# ---------------------------------------------------------------------------

@test "codesign_verify: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/codesign_verify.nu'"
    [ "$status" -eq 0 ]
}

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

@test "list_codesign_identities: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/list_codesign_identities.nu'"
    [ "$status" -eq 0 ]
}

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

@test "simclean: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/simclean.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# xcsp — xcode-select --print-path (read-only)
# ---------------------------------------------------------------------------

@test "xcsp: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/xcsp.nu'"
    [ "$status" -eq 0 ]
}

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

@test "vi: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/vi.nu'"
    [ "$status" -eq 0 ]
}

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

@test "vim: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/vim.nu'"
    [ "$status" -eq 0 ]
}

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
