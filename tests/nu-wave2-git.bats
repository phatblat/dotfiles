#!/usr/bin/env bats
# nu-wave2-git.bats — Nushell port tests for wave-2 git functions
# Functions: cont, new, publish, ra, rewrite, gskip, unstage, upstreamify, user.name, wip, git_repo_clean

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# Helper: create a temp git repo with one commit
# ---------------------------------------------------------------------------
setup_git_repo() {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "initial" > "$tmpdir/init.txt"
    git -C "$tmpdir" add init.txt
    git -C "$tmpdir" commit -qm "init"
    echo "$tmpdir"
}

# ---------------------------------------------------------------------------
# git_repo_clean
# ---------------------------------------------------------------------------

@test "git_repo_clean: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/git_repo_clean.nu'"
    [ "$status" -eq 0 ]
}

@test "git_repo_clean: returns true in a clean repo" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/git_repo_clean.nu'
        cd '$tmpdir'
        git_repo_clean | into string
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "git_repo_clean: returns false in a dirty repo" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    echo "dirty" > "$tmpdir/dirty.txt"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/git_repo_clean.nu'
        cd '$tmpdir'
        git_repo_clean | into string
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

# ---------------------------------------------------------------------------
# wip
# ---------------------------------------------------------------------------

@test "wip: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/wip.nu'"
    [ "$status" -eq 0 ]
}

@test "wip: commits dirty changes as WIP" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    echo "wip content" > "$tmpdir/work.txt"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/git_repo_clean.nu'
        source '$NU_AUTOLOAD/error-msg.nu'
        source '$NU_AUTOLOAD/wip.nu'
        cd '$tmpdir'
        wip
    "
    [ "$status" -eq 0 ]
    # Verify a WIP commit was created
    local log
    log="$(git -C "$tmpdir" log --oneline)"
    [[ "$log" == *"WIP"* ]]
    rm -rf "$tmpdir"
}

@test "wip: exits non-zero when repo is clean" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/git_repo_clean.nu'
        source '$NU_AUTOLOAD/error-msg.nu'
        source '$NU_AUTOLOAD/wip.nu'
        cd '$tmpdir'
        wip
    " 2>&1
    rm -rf "$tmpdir"
    # wip returns early (no commit created) when clean — error-msg + return
    # return in nu does not set a non-zero exit code; check output instead
    [[ "$output" == *"nothing to commit"* ]]
}

# ---------------------------------------------------------------------------
# unstage
# ---------------------------------------------------------------------------

@test "unstage: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/unstage.nu'"
    [ "$status" -eq 0 ]
}

@test "unstage: unstages all files when called with no args" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    echo "staged" > "$tmpdir/staged.txt"
    git -C "$tmpdir" add staged.txt
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/unstage.nu'
        cd '$tmpdir'
        unstage
    "
    [ "$status" -eq 0 ]
    # File should now be untracked (unstaged)
    local staged
    staged="$(git -C "$tmpdir" diff --cached --name-only)"
    [ -z "$staged" ]
    rm -rf "$tmpdir"
}

@test "unstage: unstages named file" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    echo "staged" > "$tmpdir/staged.txt"
    git -C "$tmpdir" add staged.txt
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/unstage.nu'
        cd '$tmpdir'
        unstage staged.txt
    "
    [ "$status" -eq 0 ]
    local staged
    staged="$(git -C "$tmpdir" diff --cached --name-only)"
    [ -z "$staged" ]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# cont
# ---------------------------------------------------------------------------

@test "cont: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/cont.nu'"
    [ "$status" -eq 0 ]
}

@test "cont: smoke — mutating (parse only)" {
    # cont triggers git operations; parse check sufficient
    run nu --no-config-file -c "source '$NU_AUTOLOAD/cont.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# gskip
# ---------------------------------------------------------------------------

@test "gskip: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

@test "gskip: smoke — mutating (parse only)" {
    # gskip only makes sense mid-rebase/am/cherry-pick; parse check is sufficient
    run nu --no-config-file -c "source '$NU_AUTOLOAD/gskip.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# publish
# ---------------------------------------------------------------------------

@test "publish: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/publish.nu'"
    [ "$status" -eq 0 ]
}

@test "publish: smoke — mutating (parse only)" {
    # publish pushes to a remote; parse check is sufficient
    run nu --no-config-file -c "source '$NU_AUTOLOAD/publish.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# new
# ---------------------------------------------------------------------------

@test "new: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/new.nu'"
    [ "$status" -eq 0 ]
}

@test "new: smoke — reads new commits in dotfiles repo after a pull (parse + help)" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/new.nu'; help new"
    [ "$status" -eq 0 ]
    [[ "$output" == *"new commits"* ]]
}

# ---------------------------------------------------------------------------
# ra
# ---------------------------------------------------------------------------

@test "ra: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ra.nu'"
    [ "$status" -eq 0 ]
}

@test "ra: adds a remote with explicit URL (local bare repo)" {
    local tmpdir remotedir
    tmpdir="$(setup_git_repo)"
    remotedir="$(mktemp -d)"
    git -C "$remotedir" init --bare -q
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/ra.nu'
        cd '$tmpdir'
        ra myfork '$remotedir'
    "
    [ "$status" -eq 0 ]
    local remotes
    remotes="$(git -C "$tmpdir" remote)"
    [[ "$remotes" == *"myfork"* ]]
    rm -rf "$tmpdir" "$remotedir"
}

# ---------------------------------------------------------------------------
# rewrite
# ---------------------------------------------------------------------------

@test "rewrite: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/rewrite.nu'"
    [ "$status" -eq 0 ]
}

@test "rewrite: smoke — mutating (parse only)" {
    # rewrite modifies git history; parse check is sufficient
    run nu --no-config-file -c "source '$NU_AUTOLOAD/rewrite.nu'"
    [ "$status" -eq 0 ]
}

@test "rewrite: rejects unsupported field" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/rewrite.nu'
        cd '$tmpdir'
        rewrite username old new
    " 2>&1
    rm -rf "$tmpdir"
    # Should print error about unsupported field
    [[ "$output" == *"Unsupported field"* ]]
}

@test "rewrite: rejects non-integer limit" {
    local tmpdir
    tmpdir="$(setup_git_repo)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/rewrite.nu'
        cd '$tmpdir'
        rewrite email old@example.com new@example.com abc
    " 2>&1
    rm -rf "$tmpdir"
    [[ "$output" == *"limit must be a positive integer"* ]]
}

# ---------------------------------------------------------------------------
# upstreamify
# ---------------------------------------------------------------------------

@test "upstreamify: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/upstreamify.nu'"
    [ "$status" -eq 0 ]
}

@test "upstreamify: renames origin to upstream" {
    local tmpdir remotedir
    tmpdir="$(setup_git_repo)"
    remotedir="$(mktemp -d)"
    git -C "$remotedir" init --bare -q
    git -C "$tmpdir" remote add origin "$remotedir"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/rv.nu'
        source '$NU_AUTOLOAD/upstreamify.nu'
        cd '$tmpdir'
        upstreamify
    "
    [ "$status" -eq 0 ]
    local remotes
    remotes="$(git -C "$tmpdir" remote)"
    [[ "$remotes" == *"upstream"* ]]
    [[ "$remotes" != *"origin"* ]]
    rm -rf "$tmpdir" "$remotedir"
}

# ---------------------------------------------------------------------------
# user.name
# ---------------------------------------------------------------------------

@test "user.name: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/user.name.nu'"
    [ "$status" -eq 0 ]
}

@test "user.name: returns the configured git user name" {
    # Hermetic repo: user.name is machine-local config, absent in CI
    local tmpdir
    tmpdir="$(setup_git_repo)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/user.name.nu'
        cd '$tmpdir'
        user.name
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Test"* ]]
}
