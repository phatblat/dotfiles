#!/usr/bin/env bats
# nu-pilot.bats — Nushell port tests for pilot batch (git/brew wrappers)
# Functions: af, bconfig, be, bi, bo, bra, bu, bv, lga, subrepo

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# af — git add --force (mutating: test parse + help only)
# ---------------------------------------------------------------------------

@test "af: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/af.nu'"
    [ "$status" -eq 0 ]
}

@test "af: smoke — stages a file with --force in temp git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "hello" > "$tmpdir/test.txt"
    # Add the file to .gitignore to test that --force overrides it
    echo "test.txt" > "$tmpdir/.gitignore"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/af.nu'
        cd '$tmpdir'
        af test.txt
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# bconfig — configure Bundler local settings (mutating: parse test + temp dir)
# ---------------------------------------------------------------------------

@test "bconfig: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bconfig.nu'"
    [ "$status" -eq 0 ]
}

@test "bconfig: smoke — runs five bundle config commands in a temp dir" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/bconfig.nu'
        cd '$tmpdir'
        bconfig
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# be — bundle exec (mutating/interactive: parse + wrapped flag test)
# ---------------------------------------------------------------------------

@test "be: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/be.nu'"
    [ "$status" -eq 0 ]
}

@test "be: smoke — forwards command to bundle exec (requires Gemfile, skipped without one)" {
    # bundle exec requires a Gemfile; run in a temp dir with one to confirm forwarding
    local tmpdir
    tmpdir="$(mktemp -d)"
    echo "source 'https://rubygems.org'" > "$tmpdir/Gemfile"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/be.nu'
        cd '$tmpdir'
        be ruby --version
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ruby"* ]]
}

# ---------------------------------------------------------------------------
# bi — bundle install (mutating: parse test only)
# ---------------------------------------------------------------------------

@test "bi: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bi.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# bo — bundle outdated (read-only but needs Gemfile: parse only)
# ---------------------------------------------------------------------------

@test "bo: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bo.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# bra — git branch -avv (read-only)
# ---------------------------------------------------------------------------

@test "bra: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bra.nu'"
    [ "$status" -eq 0 ]
}

@test "bra: smoke — lists branches in a temp git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q -b bra-test-branch
    git -C "$tmpdir" -c user.email=test@test.com -c user.name=Test \
        -c commit.gpgsign=false commit -q --allow-empty -m init
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/bra.nu'
        cd '$tmpdir'
        bra
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"bra-test-branch"* ]]
}

# ---------------------------------------------------------------------------
# bu — bundle update (mutating: parse test only)
# ---------------------------------------------------------------------------

@test "bu: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bu.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# bv — bundle --version (read-only)
# ---------------------------------------------------------------------------

@test "bv: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bv.nu'"
    [ "$status" -eq 0 ]
}

@test "bv: smoke — outputs a version string" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/bv.nu'
        bv
    "
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

# ---------------------------------------------------------------------------
# lga — git log --all --graph (read-only)
# ---------------------------------------------------------------------------

@test "lga: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/lga.nu'"
    [ "$status" -eq 0 ]
}

@test "lga: smoke — outputs graph with commit hashes" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/lga.nu'
        cd '$HOME'
        lga -5
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"*"* ]]
}

# ---------------------------------------------------------------------------
# subrepo — git subrepo wrapper (read-only with help)
# ---------------------------------------------------------------------------

@test "subrepo: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/subrepo.nu'"
    [ "$status" -eq 0 ]
}

@test "subrepo: smoke — forwards version flag to git subrepo" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/subrepo.nu'
        subrepo version
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"git-subrepo"* ]]
}
