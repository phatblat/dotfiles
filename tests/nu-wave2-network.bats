#!/usr/bin/env bats
# nu-wave2-network.bats — Nushell port tests for wave-2 network functions:
#   flushdns, ip, en1, openports, sshnewkey, sshkeyfingerprint, sshkey,
#   moj_host, pull_ssh_config, gskip (renamed from skip)

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# user_is_admin (helper, dependency of flushdns)
# ---------------------------------------------------------------------------

@test "user_is_admin: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_mac.nu'; source '$AUTOLOAD/is_linux.nu'; source '$AUTOLOAD/user_is_admin.nu'"
    [ "$status" -eq 0 ]
}

@test "user_is_admin: returns a bool" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        user_is_admin | describe
    "
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

@test "user_is_admin: current user is admin on dev machine" {
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
# flushdns (mutating — parse + admin-guard test only)
# ---------------------------------------------------------------------------

@test "flushdns: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/flushdns.nu'
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# en1 (read-only — wraps ifconfig)
# ---------------------------------------------------------------------------

@test "en1: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/en1.nu'"
    [ "$status" -eq 0 ]
}

@test "en1: smoke — ifconfig en1 output has interface name" {
    run nu --no-config-file -c "source '$AUTOLOAD/en1.nu'; en1 | into string" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"en1"* ]]
}

# ---------------------------------------------------------------------------
# ip (read-only — requires active en1 inet address)
# ---------------------------------------------------------------------------

@test "ip: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/en1.nu'; source '$AUTOLOAD/ip.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# openports (read-only)
# ---------------------------------------------------------------------------

@test "openports: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/openports.nu'"
    [ "$status" -eq 0 ]
}

@test "openports: smoke — returns a list" {
    run nu --no-config-file -c "source '$AUTOLOAD/openports.nu'; openports | length"
    [ "$status" -eq 0 ]
    # Any non-negative integer is acceptable
    [[ "$output" =~ ^[0-9]+$ ]]
}

@test "openports: smoke — each line contains LISTEN" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/openports.nu'
        openports | all { |line| \$line | str contains 'LISTEN' } | into string
    "
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# sshnewkey (mutating — parse test only; keygen writes files)
# ---------------------------------------------------------------------------

@test "sshnewkey: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshnewkey.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# sshkey (read-only)
# ---------------------------------------------------------------------------

@test "sshkey: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshkey.nu'"
    [ "$status" -eq 0 ]
}

@test "sshkey: smoke — returns an existing .pub file path" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshkey.nu'; sshkey"
    [ "$status" -eq 0 ]
    [[ "$output" == *".pub"* ]]
    [ -f "$output" ]
}

# ---------------------------------------------------------------------------
# sshkeyfingerprint (read-only)
# ---------------------------------------------------------------------------

@test "sshkeyfingerprint: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshkey.nu'; source '$AUTOLOAD/sshkeyfingerprint.nu'"
    [ "$status" -eq 0 ]
}

@test "sshkeyfingerprint: smoke — output contains MD5 fingerprint" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/sshkey.nu'
        source '$AUTOLOAD/sshkeyfingerprint.nu'
        sshkeyfingerprint
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"MD5:"* ]]
}

# ---------------------------------------------------------------------------
# moj_host (read-only)
# ---------------------------------------------------------------------------

@test "moj_host: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/moj_host.nu'"
    [ "$status" -eq 0 ]
}

@test "moj_host: smoke — returns a non-empty string" {
    run nu --no-config-file -c "source '$AUTOLOAD/moj_host.nu'; moj_host"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# ---------------------------------------------------------------------------
# pull_ssh_config (mutating / network — parse + hostname guard test only)
# ---------------------------------------------------------------------------

@test "pull_ssh_config: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/pull_ssh_config.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# gskip (mutating git — parse + no-active-operation test)
# ---------------------------------------------------------------------------

@test "gskip: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: smoke — exits non-zero outside a rebase/cherry-pick/am context" {
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
    # git --skip with no active operation exits non-zero
    [ "$status" -ne 0 ]
}
