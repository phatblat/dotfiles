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
# fork — open -a Fork (macOS GUI app: never launched; `open` is stubbed)
# ---------------------------------------------------------------------------

# `open -a` hands the caller's whole environment to the GUI app, which keeps it
# for days. Git debug vars inherited that way wedge every git child Fork spawns
# (they block in write() on a pipe Fork stopped draining). Both ports must
# strip them while leaving everything else — notably PATH — intact.
_fork_stub_dir() {
    local dir
    dir="$(mktemp -d)"
    printf '#!/bin/sh\nenv > "%s/seen.txt"\necho "ARGS: $*" >> "%s/seen.txt"\n' "$dir" "$dir" >"$dir/open"
    chmod +x "$dir/open"
    echo "$dir"
}

_fork_poison_env() {
    export GIT_TRACE=1 GIT_TRACE_PERFORMANCE=1 GIT_TRACE2=1 GIT_CURL_VERBOSE=1
    export GIT_SSH_COMMAND='ssh -vvv'
    export GIT_DIR=/tmp/fake/.git GIT_WORK_TREE=/tmp/fake
    export FORK_PROBE_KEEP=must-survive
}

# Asserts on $1/seen.txt written by the stub.
#
# Leak checks use `if grep; then return 1; fi` rather than `! grep -q`: bash
# exempts a command whose status is inverted with `!` from errexit, so the
# negated form silently passes even when the variable IS present.
_fork_assert_clean() {
    local dir="$1" leaked
    [ -f "$dir/seen.txt" ]
    leaked="$(grep -E '^(GIT_TRACE|GIT_TRACE_SETUP|GIT_TRACE_PERFORMANCE|GIT_TRACE_PACKET|GIT_TRACE_PACK_ACCESS|GIT_TRACE_SHALLOW|GIT_TRACE_CURL|GIT_TRACE2|GIT_TRACE2_EVENT|GIT_TRACE2_PERF|GIT_CURL_VERBOSE|GIT_SSH_COMMAND|GIT_DIR|GIT_WORK_TREE|GIT_INDEX_FILE|GIT_OBJECT_DIRECTORY|GIT_COMMON_DIR)=' "$dir/seen.txt" || true)"
    if [ -n "$leaked" ]; then
        echo "env leaked to Fork:" >&2
        echo "$leaked" >&2
        return 1
    fi
    # Unrelated variables must still pass through.
    grep -qx 'FORK_PROBE_KEEP=must-survive' "$dir/seen.txt"
    # And it must still have asked to open the app.
    grep -qx 'ARGS: -a Fork' "$dir/seen.txt"
}

@test "fork (nu): strips git debug env, keeps everything else" {
    local dir
    dir="$(_fork_stub_dir)"
    _fork_poison_env
    PATH="$dir:$PATH" run nu --no-config-file -c "
        source '$NU_AUTOLOAD/fork.nu'
        fork
    "
    [ "$status" -eq 0 ]
    _fork_assert_clean "$dir"
    rm -rf "$dir"
}

@test "fork (zsh): strips git debug env, keeps everything else" {
    local dir
    dir="$(_fork_stub_dir)"
    _fork_poison_env
    PATH="$dir:$PATH" run zsh --no-rcs "$HOME/.config/zsh/functions/fork"
    [ "$status" -eq 0 ]
    _fork_assert_clean "$dir"
    rm -rf "$dir"
}

# ---------------------------------------------------------------------------
# ginit — git init (mutating: parse + temp dir smoke)
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# ls-remote — git ls-remote (read-only network: parse + smoke)
# ---------------------------------------------------------------------------

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
