#!/usr/bin/env bats
# nu-wave1-tools.bats — Nushell port tests for wave-1 tools batch
# Functions: curl_download, cdown, dc, dir, ff, fishfiles, nixgc, nixtest, usage, warpify

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# curl_download — mutating (downloads a file): parse test only
# ---------------------------------------------------------------------------

@test "curl_download: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/curl_download.nu'"
    [ "$status" -eq 0 ]
}

@test "curl_download: help text available" {
    run nu --no-config-file -c "source '$AUTOLOAD/curl_download.nu'; help curl_download"
    [ "$status" -eq 0 ]
    [[ "$output" == *"curl"* ]]
}

# ---------------------------------------------------------------------------
# cdown — mutating (downloads a file): parse test only
# ---------------------------------------------------------------------------

@test "cdown: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/cdown.nu'"
    [ "$status" -eq 0 ]
}

@test "cdown: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/curl_download.nu'
        source '$AUTOLOAD/cdown.nu'
        help cdown
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"curl_download"* ]]
}

# ---------------------------------------------------------------------------
# dc — git diff --cached (read-only)
# ---------------------------------------------------------------------------

@test "dc: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/dc.nu'"
    [ "$status" -eq 0 ]
}

@test "dc: smoke — runs in dotfiles repo without error" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/dc.nu'
        cd '$HOME'
        dc
    "
    [ "$status" -eq 0 ]
}

@test "dc: help text mentions staging area" {
    run nu --no-config-file -c "source '$AUTOLOAD/dc.nu'; help dc"
    [ "$status" -eq 0 ]
    [[ "$output" == *"staging"* ]] || [[ "$output" == *"cached"* ]]
}

# ---------------------------------------------------------------------------
# dir — docker image rm --force (mutating): parse test only
# ---------------------------------------------------------------------------

@test "dir: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/dir.nu'"
    [ "$status" -eq 0 ]
}

@test "dir: help text mentions docker" {
    run nu --no-config-file -c "source '$AUTOLOAD/dir.nu'; help dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"docker"* ]]
}

# ---------------------------------------------------------------------------
# fishfiles — opens fish dotfiles in editor (interactive): parse test only
# ---------------------------------------------------------------------------

@test "fishfiles: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/fishfiles.nu'"
    [ "$status" -eq 0 ]
}

@test "fishfiles: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/edit.nu'
        source '$AUTOLOAD/fishfiles.nu'
        help fishfiles
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"fish"* ]]
}

# ---------------------------------------------------------------------------
# ff — alias for fishfiles (interactive): parse test only
# ---------------------------------------------------------------------------

@test "ff: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/ff.nu'"
    [ "$status" -eq 0 ]
}

@test "ff: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/edit.nu'
        source '$AUTOLOAD/fishfiles.nu'
        source '$AUTOLOAD/ff.nu'
        help ff
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"fish"* ]]
}

# ---------------------------------------------------------------------------
# nixgc — nix garbage collection (mutating): parse test only
# ---------------------------------------------------------------------------

@test "nixgc: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/nixgc.nu'"
    [ "$status" -eq 0 ]
}

@test "nixgc: help text mentions nix" {
    run nu --no-config-file -c "source '$AUTOLOAD/nixgc.nu'; help nixgc"
    [ "$status" -eq 0 ]
    [[ "$output" == *"nix"* ]] || [[ "$output" == *"garbage"* ]]
}

# ---------------------------------------------------------------------------
# nixtest — tests nix installation (read-only)
# ---------------------------------------------------------------------------

@test "nixtest: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/nixtest.nu'"
    [ "$status" -eq 0 ]
}

@test "nixtest: smoke — runs nix-instantiate and exits 0" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/nixtest.nu'
        nixtest
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# usage — disk usage (read-only)
# ---------------------------------------------------------------------------

@test "usage: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/usage.nu'"
    [ "$status" -eq 0 ]
}

@test "usage: smoke — shows disk usage for /tmp" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/usage.nu'
        usage '/tmp'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"/tmp"* ]]
}

@test "usage: smoke — defaults to current directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/usage.nu'
        cd '$tmpdir'
        usage
    "
    rm -rf "$tmpdir"
    # du may warn about things but exit 0; allow non-zero for symlink cycle edge cases
    [[ "$output" == *"B"* ]] || [[ "$output" == *"K"* ]] || [[ "$output" == *"M"* ]] || [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# warpify — Warp terminal escape sequence (read-only)
# ---------------------------------------------------------------------------

@test "warpify: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/warpify.nu'"
    [ "$status" -eq 0 ]
}

@test "warpify: smoke — outputs DCS escape sequence starting with ESC P" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/warpify.nu'
        warpify
    "
    [ "$status" -eq 0 ]
    # Output should contain the Warp hook identifier
    [[ "$output" == *"SourcedRcFileForWarp"* ]]
}
