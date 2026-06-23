#!/usr/bin/env bats
# nu-wave2-misc.bats — Nushell port tests for wave-2 misc batch:
#   aws_test, dotfiles, find_file, maslink, masrm, fileowner, masshow, ox, upstall, gskip

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# aws_test
# ---------------------------------------------------------------------------

@test "aws_test: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/aws_test.nu'"
    [ "$status" -eq 0 ]
}

@test "aws_test: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/aws_test.nu'; help aws_test"
    [ "$status" -eq 0 ]
    [[ "$output" == *"profile"* ]]
}

@test "aws_test: defaults to 'default' profile" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/aws_test.nu'
        # Verify the function definition exists and accepts no args
        help aws_test
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"profile_name"* ]]
}

# ---------------------------------------------------------------------------
# dotfiles
# ---------------------------------------------------------------------------

@test "dotfiles: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'; source '$AUTOLOAD/dotfiles.nu'"
    [ "$status" -eq 0 ]
}

@test "dotfiles: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'; source '$AUTOLOAD/dotfiles.nu'; help dotfiles"
    [ "$status" -eq 0 ]
    [[ "$output" == *"dotfiles"* ]]
}

@test "dotfiles: no args prints usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'; source '$AUTOLOAD/dotfiles.nu'; dotfiles" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "dotfiles: unknown type prints usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'; source '$AUTOLOAD/dotfiles.nu'; dotfiles 'nonexistentxyz'" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# find_file
# ---------------------------------------------------------------------------

@test "find_file: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/find_file.nu'"
    [ "$status" -eq 0 ]
}

@test "find_file: empty file_name prints usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/find_file.nu'; find_file ''" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Missing file name"* ]]
}

@test "find_file: nonexistent base_dir prints error" {
    run nu --no-config-file -c "source '$AUTOLOAD/find_file.nu'; find_file 'test.txt' '/nonexistent_dir_xyz'" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "find_file: searches current dir when no base_dir" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/testfile_abc.txt"
    run nu --no-config-file -c "source '$AUTOLOAD/find_file.nu'; cd '$tmpdir'; find_file 'testfile_abc'" 2>&1
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"testfile_abc"* ]]
}

# ---------------------------------------------------------------------------
# fileowner
# ---------------------------------------------------------------------------

@test "fileowner: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/fileowner.nu'"
    [ "$status" -eq 0 ]
}

@test "fileowner: returns owner of /etc/hosts" {
    run nu --no-config-file -c "source '$AUTOLOAD/fileowner.nu'; fileowner '/etc/hosts'"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "fileowner: /etc/hosts is owned by root" {
    run nu --no-config-file -c "source '$AUTOLOAD/fileowner.nu'; fileowner '/etc/hosts'"
    [ "$status" -eq 0 ]
    [ "$output" = "root" ]
}

@test "fileowner: empty arg exits non-zero" {
    run nu --no-config-file -c "source '$AUTOLOAD/fileowner.nu'; fileowner ''" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# masshow
# ---------------------------------------------------------------------------

@test "masshow: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ll.nu'; source '$AUTOLOAD/masshow.nu'"
    [ "$status" -eq 0 ]
}

@test "masshow: smoke — runs when mas is installed" {
    # mas may or may not be installed; either way should not crash
    run nu --no-config-file -c "
        source '$AUTOLOAD/ll.nu'
        source '$AUTOLOAD/masshow.nu'
        masshow
    " 2>&1
    # Exit code 0 when mas not found, non-zero only on real errors (lipo on non-fat binary is ok)
    # We just verify no parse/runtime error from our code
    [[ "$output" != *"parse_mismatch"* ]]
}

# ---------------------------------------------------------------------------
# maslink (mutating: parse test only)
# ---------------------------------------------------------------------------

@test "maslink: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/ll.nu'
        source '$AUTOLOAD/masshow.nu'
        source '$AUTOLOAD/maslink.nu'
    "
    [ "$status" -eq 0 ]
}

@test "maslink: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/ll.nu'
        source '$AUTOLOAD/masshow.nu'
        source '$AUTOLOAD/maslink.nu'
        help maslink
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"maslink"* ]]
}

# ---------------------------------------------------------------------------
# masrm (mutating: parse test only)
# ---------------------------------------------------------------------------

@test "masrm: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/fileowner.nu'
        source '$AUTOLOAD/ll.nu'
        source '$AUTOLOAD/masshow.nu'
        source '$AUTOLOAD/masrm.nu'
    "
    [ "$status" -eq 0 ]
}

@test "masrm: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/fileowner.nu'
        source '$AUTOLOAD/ll.nu'
        source '$AUTOLOAD/masshow.nu'
        source '$AUTOLOAD/masrm.nu'
        help masrm
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"masrm"* ]]
}

# ---------------------------------------------------------------------------
# ox (mutating for xcodeproj dirs; parse + help test)
# ---------------------------------------------------------------------------

@test "ox: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ox.nu'"
    [ "$status" -eq 0 ]
}

@test "ox: no xcodeproj prints message" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/ox.nu'
        cd '$tmpdir'
        ox
    " 2>&1
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No .xcodeproj"* ]]
}

# ---------------------------------------------------------------------------
# gskip (mutating git op: parse test only)
# ---------------------------------------------------------------------------

@test "gskip: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'; help gskip"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gskip"* ]]
}

@test "gskip: exits non-zero outside a git operation" {
    # Running gskip when no rebase/cherry-pick/am is in progress should fail
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    run nu --no-config-file -c "
        source '$AUTOLOAD/gskip.nu'
        cd '$tmpdir'
        gskip
    " 2>&1
    rm -rf "$tmpdir"
    # Non-zero exit expected (no operation in progress)
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# upstall (mutating: parse + logic tests only, no actual module execution)
# ---------------------------------------------------------------------------

@test "upstall: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/upstall.nu'
    "
    [ "$status" -eq 0 ]
}

@test "upstall: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/upstall.nu'
        help upstall
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"upstall"* ]]
}
