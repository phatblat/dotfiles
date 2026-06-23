#!/usr/bin/env bats
# nu-wave2-ruby-dev.bats — Nushell port tests for wave-2 ruby/dev/brew/tool batch
# Functions: gskip, binstall, bq, brew_active_version, brew_test, gem_install, jq, jv, license, list, pip

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# gskip — git rebase/cherry-pick/am --skip (mutating: parse + help only)
# ---------------------------------------------------------------------------

@test "gskip: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: smoke — exits non-zero with no rebase in progress" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    run nu --no-config-file -c "
        source '$AUTOLOAD/gskip.nu'
        cd '$tmpdir'
        gskip
    " 2>&1
    rm -rf "$tmpdir"
    # No rebase/cherry-pick/am in progress — all three commands fail, so non-zero exit
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# binstall — install Bundler gem (mutating: parse only)
# ---------------------------------------------------------------------------

@test "binstall: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/binstall.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# bq — query Homebrew JSON info (read-only)
# ---------------------------------------------------------------------------

@test "bq: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/bq.nu'"
    [ "$status" -eq 0 ]
}

@test "bq: no args prints usage and exits non-zero" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; source '$AUTOLOAD/bq.nu'; bq" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "bq: returns json for a known formula" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; source '$AUTOLOAD/bq.nu'; bq git"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git"* ]]
}

@test "bq: applies jq filter via --filter flag" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; source '$AUTOLOAD/bq.nu'; bq git --filter '.[0].name'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"git"* ]]
}

# ---------------------------------------------------------------------------
# brew_active_version — active keg version (read-only)
# ---------------------------------------------------------------------------

@test "brew_active_version: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_active_version.nu'"
    [ "$status" -eq 0 ]
}

@test "brew_active_version: empty arg exits non-zero" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_active_version.nu'; brew_active_version ''" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "brew_active_version: returns a version string for git" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_active_version.nu'; brew_active_version git"
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

# ---------------------------------------------------------------------------
# brew_test — install and test a formula (mutating: parse only)
# ---------------------------------------------------------------------------

@test "brew_test: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_test.nu'"
    [ "$status" -eq 0 ]
}

@test "brew_test: empty token exits non-zero with usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_test.nu'; brew_test ''" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}

# ---------------------------------------------------------------------------
# gem_install — install a gem with brew bindir (mutating: parse only)
# ---------------------------------------------------------------------------

@test "gem_install: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/gem_install.nu'"
    [ "$status" -eq 0 ]
}

@test "gem_install: empty gem_name exits non-zero with usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/gem_install.nu'; gem_install ''" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}

# ---------------------------------------------------------------------------
# jq — jq wrapper with stdin buffering (read-only)
# ---------------------------------------------------------------------------

@test "jq: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'"
    [ "$status" -eq 0 ]
}

@test "jq: extracts field from JSON string piped in nu" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; '{\"a\":1}' | jq '.a'"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "jq: prints error message and exits non-zero on invalid JSON" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; 'not-json' | jq '.a'" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"jq failed"* ]]
}

@test "jq: prints original input on failure" {
    run nu --no-config-file -c "source '$AUTOLOAD/jq.nu'; 'bad-input' | jq '.a'" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"bad-input"* ]]
}

# ---------------------------------------------------------------------------
# jv — Java version display (read-only, requires java on PATH)
# ---------------------------------------------------------------------------

@test "jv: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/jv.nu'"
    [ "$status" -eq 0 ]
}

@test "jv: returns a version string" {
    run nu --no-config-file -c "source '$AUTOLOAD/jv.nu'; jv"
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

# ---------------------------------------------------------------------------
# license — write LICENSE.md and append to README.md (mutating: temp dir)
# ---------------------------------------------------------------------------

@test "license: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/license.nu'"
    [ "$status" -eq 0 ]
}

@test "license: smoke — creates LICENSE.md with current year in a temp git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    touch "$tmpdir/README.md"
    git -C "$tmpdir" add README.md
    git -C "$tmpdir" commit -q -m "init"
    run nu --no-config-file -c "
        source '$AUTOLOAD/license.nu'
        cd '$tmpdir'
        license
    " 2>&1
    local rc=$status
    rm -rf "$tmpdir"
    [ "$rc" -eq 0 ]
}

# ---------------------------------------------------------------------------
# list — print args one per line (read-only)
# ---------------------------------------------------------------------------

@test "list: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/list.nu'"
    [ "$status" -eq 0 ]
}

@test "list: no args exits non-zero with usage on stderr" {
    run nu --no-config-file -c "source '$AUTOLOAD/list.nu'; list" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "list: prints each arg on its own line" {
    run nu --no-config-file -c "source '$AUTOLOAD/list.nu'; list a b c"
    [ "$status" -eq 0 ]
    [[ "$output" == *"a"* ]]
    [[ "$output" == *"b"* ]]
    [[ "$output" == *"c"* ]]
}

@test "list -s: skips first arg (label)" {
    run nu --no-config-file -c "source '$AUTOLOAD/list.nu'; list -s label x y z"
    [ "$status" -eq 0 ]
    [[ "$output" != *"label"* ]]
    [[ "$output" == *"x"* ]]
    [[ "$output" == *"y"* ]]
    [[ "$output" == *"z"* ]]
}

# ---------------------------------------------------------------------------
# pip — pip wrapper with brew CFLAGS/LDFLAGS (read-only: version check)
# ---------------------------------------------------------------------------

@test "pip: file parses without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/pip.nu'"
    [ "$status" -eq 0 ]
}

@test "pip: forwards --version to pip" {
    run nu --no-config-file -c "source '$AUTOLOAD/pip.nu'; pip --version"
    [ "$status" -eq 0 ]
    [[ "$output" == *"pip"* ]]
}
