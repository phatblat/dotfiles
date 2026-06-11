#!/usr/bin/env bats
# nu-wave1-system.bats — Nushell port tests for wave-1 system/utility batch
# Functions: octodec, osversion, phatmini, sa, sha256, sshtest, surf, suri, sysinfo, tmsnapshots

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# octodec — ssh phatblat@octodec.local (mutating/network: parse only)
# ---------------------------------------------------------------------------

@test "octodec: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/octodec.nu'"
    [ "$status" -eq 0 ]
}

@test "octodec: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/octodec.nu'; help octodec"
    [ "$status" -eq 0 ]
    [[ "$output" == *"octodec"* ]]
}

# ---------------------------------------------------------------------------
# osversion — sw_vers -productVersion (read-only, macOS only)
# ---------------------------------------------------------------------------

@test "osversion: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/osversion.nu'"
    [ "$status" -eq 0 ]
}

@test "osversion: smoke — outputs a version string" {
    run nu --no-config-file -c "source '$AUTOLOAD/osversion.nu'; osversion"
    [ "$status" -eq 0 ]
    # macOS version looks like 14.5 or 15.0.1 or 26.5.1
    [[ "$output" =~ ^[0-9]+\.[0-9]+ ]]
}

# ---------------------------------------------------------------------------
# phatmini — ssh phatblat@phatmini.local (mutating/network: parse only)
# ---------------------------------------------------------------------------

@test "phatmini: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/phatmini.nu'"
    [ "$status" -eq 0 ]
}

@test "phatmini: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/phatmini.nu'; help phatmini"
    [ "$status" -eq 0 ]
    [[ "$output" == *"phatmini"* ]]
}

# ---------------------------------------------------------------------------
# sa — git status (read-only)
# ---------------------------------------------------------------------------

@test "sa: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/sa.nu'"
    [ "$status" -eq 0 ]
}

@test "sa: smoke — git status in dotfiles repo exits 0" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/sa.nu'
        cd '$HOME'
        sa --short
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# sha256 — shasum --algorithm 256 wrapper (read-only)
# ---------------------------------------------------------------------------

@test "sha256: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/sha256.nu'"
    [ "$status" -eq 0 ]
}

@test "sha256: smoke — checksums a known file" {
    run nu --no-config-file -c "source '$AUTOLOAD/sha256.nu'; sha256 '$AUTOLOAD/sha256.nu'"
    [ "$status" -eq 0 ]
    # shasum output: <64-hex-chars>  <path>
    [[ "$output" =~ ^[0-9a-f]{64} ]]
}

@test "sha256: error on empty args" {
    run nu --no-config-file -c "source '$AUTOLOAD/sha256.nu'; sha256" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: sha256"* ]]
}

# ---------------------------------------------------------------------------
# sshtest — ssh -T git@github.com (network: parse only)
# ---------------------------------------------------------------------------

@test "sshtest: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshtest.nu'"
    [ "$status" -eq 0 ]
}

@test "sshtest: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/sshtest.nu'; help sshtest"
    [ "$status" -eq 0 ]
    [[ "$output" == *"GitHub"* ]]
}

# ---------------------------------------------------------------------------
# surf — open path in Windsurf editor (windsurf not installed: parse only)
# ---------------------------------------------------------------------------

@test "surf: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/surf.nu'"
    [ "$status" -eq 0 ]
}

@test "surf: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/surf.nu'; help surf"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Windsurf"* ]]
}

# ---------------------------------------------------------------------------
# suri — git submodule update --recursive --init (mutating: parse + help)
# ---------------------------------------------------------------------------

@test "suri: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/suri.nu'"
    [ "$status" -eq 0 ]
}

@test "suri: smoke — runs in repo with no submodules exits 0" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    run nu --no-config-file -c "
        source '$AUTOLOAD/suri.nu'
        cd '$tmpdir'
        suri
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# sysinfo — uname + sw_vers + system_profiler (read-only, macOS only)
# ---------------------------------------------------------------------------

@test "sysinfo: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/sysinfo.nu'"
    [ "$status" -eq 0 ]
}

@test "sysinfo: smoke — outputs kernel and version info" {
    run nu --no-config-file -c "source '$AUTOLOAD/sysinfo.nu'; sysinfo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Darwin"* ]]
}

# ---------------------------------------------------------------------------
# tmsnapshots — tmutil listlocalsnapshots / (read-only, macOS only)
# ---------------------------------------------------------------------------

@test "tmsnapshots: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/tmsnapshots.nu'"
    [ "$status" -eq 0 ]
}

@test "tmsnapshots: smoke — runs without error and produces output" {
    run nu --no-config-file -c "source '$AUTOLOAD/tmsnapshots.nu'; tmsnapshots"
    [ "$status" -eq 0 ]
    # Output always starts with this header line
    [[ "$output" == *"Snapshots for disk /"* ]]
}
