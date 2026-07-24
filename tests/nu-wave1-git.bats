#!/usr/bin/env bats
# nu-wave1-git.bats — Nushell port tests for wave-1 git/claude wrappers
# Functions: ccc, ccr, cxc, diff, fork, ginit, git_clean, ls-remote, pp, root, untracked, user.email

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# ccc — claude --continue (mutating/interactive: parse check only)
# ---------------------------------------------------------------------------

@test "ccc: file parses without error" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/cc.nu'
        source '$NU_AUTOLOAD/ccc.nu'
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ccr — claude --resume (mutating/interactive: parse check only)
# ---------------------------------------------------------------------------

@test "ccr: file parses without error" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/cc.nu'
        source '$NU_AUTOLOAD/ccr.nu'
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# cxc — codex resume --last (mutating/interactive: parse check only)
# ---------------------------------------------------------------------------

@test "cxc: file parses without error" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/cx.nu'
        source '$NU_AUTOLOAD/cxc.nu'
    "
    [ "$status" -eq 0 ]
}

@test "cx: forwards one safe set of Codex launch arguments" {
    local fakebindir
    fakebindir="$(mktemp -d)"
    printf '#!/bin/sh\nprintf "%%s\\n" "$@"\n' >"$fakebindir/codex"
    chmod +x "$fakebindir/codex"

    run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/cx.nu'
        cx --version
    "
    rm -rf "$fakebindir"

    [ "$status" -eq 0 ]
    [ "$output" = $'--no-alt-screen\n--profile\nmain\n--version' ]
}

# ---------------------------------------------------------------------------
# diff — git diff | diff-so-fancy (read-only display)
# ---------------------------------------------------------------------------

@test "diff: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/diff.nu'"
    [ "$status" -eq 0 ]
}

@test "diff: smoke — diffs two commits in a temp git repo" {
    # Hermetic repo: the CI checkout is shallow, so HEAD~1 doesn't exist there
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email test@test.com
    git -C "$tmpdir" config user.name Test
    git -C "$tmpdir" config commit.gpgsign false
    echo one > "$tmpdir/file.txt"
    git -C "$tmpdir" add file.txt
    git -C "$tmpdir" commit -qm one
    echo two > "$tmpdir/file.txt"
    git -C "$tmpdir" commit -qam two
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/diff.nu'
        cd '$tmpdir'
        diff HEAD~1 HEAD --stat
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# fork — open -a Fork (macOS GUI app: parse check + help only)
# ---------------------------------------------------------------------------

@test "fork: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/fork.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ginit — git init (mutating: parse + temp dir smoke)
# ---------------------------------------------------------------------------

@test "ginit: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ginit.nu'"
    [ "$status" -eq 0 ]
}

@test "ginit: smoke — initializes a repo in a temp directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/ginit.nu'
        cd '$tmpdir'
        ginit
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Initialized"* ]]
}

# ---------------------------------------------------------------------------
# git_clean — git clean -xffd (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "git_clean: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/git_clean.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ls-remote — git ls-remote (read-only network: parse + smoke)
# ---------------------------------------------------------------------------

@test "ls-remote: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ls-remote.nu'"
    [ "$status" -eq 0 ]
}

@test "ls-remote: smoke — lists remote refs from origin" {
    git -C "$HOME" ls-remote --heads origin &>/dev/null || skip "origin remote is not reachable"

    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/ls-remote.nu'
        cd '$HOME'
        ls-remote --heads
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"refs/heads/"* ]]
}

# ---------------------------------------------------------------------------
# pp — push to phatblat remote (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "pp: file parses without error" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/publish.nu'
        source '$NU_AUTOLOAD/pp.nu'
    "
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# root — git rev-parse --show-toplevel (read-only)
# ---------------------------------------------------------------------------

@test "root: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/root.nu'"
    [ "$status" -eq 0 ]
}

@test "root: smoke — returns dotfiles repo root" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/root.nu'
        cd '$HOME'
        root
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"$HOME"* ]]
}

# ---------------------------------------------------------------------------
# untracked — git ls-files --others --exclude-standard (read-only)
# ---------------------------------------------------------------------------

@test "untracked: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/untracked.nu'"
    [ "$status" -eq 0 ]
}

@test "untracked: smoke — runs in dotfiles repo without error" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/untracked.nu'
        cd '$HOME'
        untracked
    "
    [ "$status" -eq 0 ]
}

@test "untracked: smoke — new file shows as untracked in temp git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    echo "test" > "$tmpdir/new_file.txt"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/untracked.nu'
        cd '$tmpdir'
        untracked
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"new_file.txt"* ]]
}

# ---------------------------------------------------------------------------
# user.email — git config user.email (read-only: shows current value)
# ---------------------------------------------------------------------------

@test "user.email: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/user.email.nu'"
    [ "$status" -eq 0 ]
}

@test "user.email: smoke — returns configured git user email" {
    # Hermetic repo: user.email is machine-local config, absent in CI
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email test@test.com
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/user.email.nu'
        cd '$tmpdir'
        user.email
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"test@test.com"* ]]
}
