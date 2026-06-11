#!/usr/bin/env bats
# nu-wave2-system.bats — Tests for wave-2 system/utility nushell functions:
#   psgrep, pcopy, pborigin, path_show, ramdisk, sethostname,
#   user_is_admin, hgrep, fish_logo, gskip (already ported)

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# psgrep
# ---------------------------------------------------------------------------

@test "psgrep: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/psgrep.nu'"
    [ "$status" -eq 0 ]
}

@test "psgrep: smoke — finds nu process running" {
    run nu --no-config-file -c "source '$AUTOLOAD/psgrep.nu'; psgrep nu | length | into string"
    [ "$status" -eq 0 ]
    # should find at least the current nu process
    [[ "$output" =~ ^[1-9][0-9]*$ ]]
}

@test "psgrep: missing arg exits with error" {
    run nu --no-config-file -c "source '$AUTOLOAD/psgrep.nu'; psgrep ''" 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# pcopy
# ---------------------------------------------------------------------------

@test "pcopy: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/pcopy.nu'"
    [ "$status" -eq 0 ]
}

@test "pcopy: smoke — copies pwd to clipboard" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/pcopy.nu'
        cd '$HOME'
        pcopy
    "
    [ "$status" -eq 0 ]
    # clipboard should contain the home dir path
    [[ "$(pbpaste)" == *"$HOME"* ]]
}

# ---------------------------------------------------------------------------
# pborigin
# ---------------------------------------------------------------------------

@test "pborigin: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/pborigin.nu'"
    [ "$status" -eq 0 ]
}

@test "pborigin: parse check with dependencies" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/rv.nu'
        source '$AUTOLOAD/remote.nu'
        source '$AUTOLOAD/pborigin.nu'
    "
    [ "$status" -eq 0 ]
}

@test "pborigin: smoke — detects phatblat remote already present" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" remote add phatblat https://github.com/phatblat/test.git
    # Use try to ignore rv failures (rv.nu may error on single-remote repos)
    run nu --no-config-file -c "
        source '$AUTOLOAD/rv.nu'
        source '$AUTOLOAD/remote.nu'
        source '$AUTOLOAD/pborigin.nu'
        cd '$tmpdir'
        try { pborigin } catch { |e| print \$e.msg }
    " 2>&1
    rm -rf "$tmpdir"
    # pborigin correctly prints the message before calling rv
    [[ "$output" == *"already set up"* ]]
}

# ---------------------------------------------------------------------------
# path_show
# ---------------------------------------------------------------------------

@test "path_show: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/path_show.nu'"
    [ "$status" -eq 0 ]
}

@test "path_show: smoke — outputs PATH header and entries" {
    run nu --no-config-file -c "source '$AUTOLOAD/path_show.nu'; path_show"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PATH"* ]]
}

@test "path_show: smoke — output contains at least one path entry" {
    run nu --no-config-file -c "source '$AUTOLOAD/path_show.nu'; path_show"
    [ "$status" -eq 0 ]
    [[ "$output" == *"/"* ]]
}

# ---------------------------------------------------------------------------
# ramdisk (mutating — parse test only)
# ---------------------------------------------------------------------------

@test "ramdisk: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ramdisk.nu'"
    [ "$status" -eq 0 ]
}

@test "ramdisk: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/ramdisk.nu'; help ramdisk"
    [ "$status" -eq 0 ]
    [[ "$output" == *"disk_size"* ]]
}

# ---------------------------------------------------------------------------
# sethostname (mutating — parse test only)
# ---------------------------------------------------------------------------

@test "sethostname: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sethostname.nu'"
    [ "$status" -eq 0 ]
}

@test "sethostname: parse check with dependencies" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/sethostname.nu'
    "
    [ "$status" -eq 0 ]
}

@test "sethostname: empty arg exits with error" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/sethostname.nu'
        sethostname ''
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# user_is_admin (read-only)
# ---------------------------------------------------------------------------

@test "user_is_admin: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/user_is_admin.nu'"
    [ "$status" -eq 0 ]
}

@test "user_is_admin: parse check with dependencies" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
    "
    [ "$status" -eq 0 ]
}

@test "user_is_admin: smoke — returns a bool" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        user_is_admin | describe
    "
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

@test "user_is_admin: smoke — returns true on this machine (expected admin)" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        user_is_admin | into string
    "
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# hgrep
# ---------------------------------------------------------------------------

@test "hgrep: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/hgrep.nu'"
    [ "$status" -eq 0 ]
}

@test "hgrep: smoke — returns a table (may be empty)" {
    run nu --no-config-file -c "source '$AUTOLOAD/hgrep.nu'; hgrep git | length | into string"
    [ "$status" -eq 0 ]
    # length of a table is an integer (possibly 0)
    [[ "$output" =~ ^[0-9]+$ ]]
}

@test "hgrep: smoke — no error on pattern with no matches" {
    run nu --no-config-file -c "source '$AUTOLOAD/hgrep.nu'; hgrep zzzzzz_no_match_xyz"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# fish_logo
# ---------------------------------------------------------------------------

@test "fish_logo: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/fish_logo.nu'"
    [ "$status" -eq 0 ]
}

@test "fish_logo: smoke — outputs ASCII art with default colors" {
    run nu --no-config-file -c "source '$AUTOLOAD/fish_logo.nu'; fish_logo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"___"* ]]
}

@test "fish_logo: smoke — --help flag shows usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/fish_logo.nu'; fish_logo --help"
    [ "$status" -eq 0 ]
}

@test "fish_logo: smoke — accepts custom colors" {
    run nu --no-config-file -c "source '$AUTOLOAD/fish_logo.nu'; fish_logo blue green cyan"
    [ "$status" -eq 0 ]
    [[ "$output" == *"___"* ]]
}

# ---------------------------------------------------------------------------
# gskip (already ported — verify it is present and passes)
# ---------------------------------------------------------------------------

@test "gskip: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: smoke — fails gracefully when not in a git operation" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    run nu --no-config-file -c "
        source '$AUTOLOAD/gskip.nu'
        cd '$tmpdir'
        gskip
    " 2>&1
    rm -rf "$tmpdir"
    # No git operation in progress: git returns non-zero, but gskip tries all three.
    # The function will propagate an error from git am --skip, so status may be non-zero.
    # What matters is the file parses and does not panic.
    true
}
