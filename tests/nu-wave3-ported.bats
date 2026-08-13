#!/usr/bin/env bats
# nu-wave3-ported.bats — Tests for wave-3 functions ported to Nushell:
#   findup, files_changed, epoc_date, gi, gh_token_test, list-authors, sortdiff,
#   lsym, prefs, displays, apps, fixperms, psync, sha1, tarball, deleted,
#   mirror, ours, ref, todo, brew_installed, brew_deps, swiftinfo, killsim, restart

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# findup
# ---------------------------------------------------------------------------

@test "findup: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/findup.nu'"
    [ "$status" -eq 0 ]
}

@test "findup: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/findup.nu'; help findup"
    [ "$status" -eq 0 ]
    [[ "$output" == *"findup"* ]]
}

@test "findup: empty pattern exits with error" {
    run nu --no-config-file -c "source '$AUTOLOAD/findup.nu'; findup ''" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "findup: finds a file in a parent directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir -p "$tmpdir/a/b/c"
    touch "$tmpdir/marker_wave3.txt"
    run nu --no-config-file -c "
        source '$AUTOLOAD/findup.nu'
        cd '$tmpdir/a/b/c'
        findup marker_wave3.txt
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"marker_wave3.txt"* ]]
}

# ---------------------------------------------------------------------------
# files_changed
# ---------------------------------------------------------------------------

@test "files_changed: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/files_changed.nu'"
    [ "$status" -eq 0 ]
}

@test "files_changed: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/files_changed.nu'; help files_changed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"files_changed"* ]]
}

@test "files_changed: lists changed files between two commits" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" config commit.gpgsign false
    touch "$tmpdir/file1.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "first"
    touch "$tmpdir/file2.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "second"
    local head
    head="$(git -C "$tmpdir" rev-parse HEAD~1)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/files_changed.nu'
        cd '$tmpdir'
        files_changed '$head'
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"file2.txt"* ]]
}

# ---------------------------------------------------------------------------
# epoc_date
# ---------------------------------------------------------------------------

@test "epoc_date: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/epoc_date.nu'"
    [ "$status" -eq 0 ]
}

@test "epoc_date: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/epoc_date.nu'; help epoc_date"
    [ "$status" -eq 0 ]
    [[ "$output" == *"epoc_date"* ]]
}

@test "epoc_date: converts epoch 0 to a 1970 date" {
    run nu --no-config-file -c "source '$AUTOLOAD/epoc_date.nu'; epoc_date 0"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1970"* ]]
}

# ---------------------------------------------------------------------------
# gi
# ---------------------------------------------------------------------------

@test "gi: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/gi.nu'"
    [ "$status" -eq 0 ]
}

@test "gi: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/gi.nu'; help gi"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gi"* ]]
}

# ---------------------------------------------------------------------------
# gh_token_test
# ---------------------------------------------------------------------------

@test "gh_token_test: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/gh_token_test.nu'"
    [ "$status" -eq 0 ]
}

@test "gh_token_test: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/gh_token_test.nu'; help gh_token_test"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gh_token_test"* ]]
}

@test "gh_token_test: reports error when GITHUB_TOKEN is unset" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/gh_token_test.nu'
        hide-env -i GITHUB_TOKEN
        gh_token_test
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"GITHUB_TOKEN"* ]]
}

# ---------------------------------------------------------------------------
# list-authors
# ---------------------------------------------------------------------------

@test "list-authors: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/list-authors.nu'"
    [ "$status" -eq 0 ]
}

@test "list-authors: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/list-authors.nu'; help list-authors"
    [ "$status" -eq 0 ]
    [[ "$output" == *"list-authors"* ]]
}

@test "list-authors: returns author from a single-commit repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "alice@example.com"
    git -C "$tmpdir" config user.name "Alice"
    git -C "$tmpdir" config commit.gpgsign false
    touch "$tmpdir/a.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "init"
    run nu --no-config-file -c "
        source '$AUTOLOAD/list-authors.nu'
        cd '$tmpdir'
        list-authors name
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Alice"* ]]
}

# ---------------------------------------------------------------------------
# sortdiff
# ---------------------------------------------------------------------------

@test "sortdiff: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sortdiff.nu'"
    [ "$status" -eq 0 ]
}

@test "sortdiff: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/sortdiff.nu'; help sortdiff"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sortdiff"* ]]
}

@test "sortdiff: shows changed lines between commits" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" config commit.gpgsign false
    echo "hello" > "$tmpdir/f.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "first"
    echo "world" > "$tmpdir/f.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "second"
    run nu --no-config-file -c "
        source '$AUTOLOAD/sortdiff.nu'
        cd '$tmpdir'
        sortdiff HEAD~1 HEAD
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"world"* ]]
}

@test "sortdiff: duplicate changed lines are suppressed (uniq -u behavior)" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" config commit.gpgsign false
    printf "aaa\nbbb\naaa\n" > "$tmpdir/f.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "first"
    printf "aaa\nbbb\nccc\naaa\n" > "$tmpdir/f.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "second"
    run nu --no-config-file -c "
        source '$AUTOLOAD/sortdiff.nu'
        cd '$tmpdir'
        sortdiff HEAD~1 HEAD
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    # +ccc appears once; +aaa appears twice so must be suppressed
    [[ "$output" == *"ccc"* ]]
    [[ "$output" != *"aaa"* ]]
}

# ---------------------------------------------------------------------------
# lsym
# ---------------------------------------------------------------------------

@test "lsym: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/lsym.nu'"
    [ "$status" -eq 0 ]
}

@test "lsym: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/lsym.nu'; help lsym"
    [ "$status" -eq 0 ]
    [[ "$output" == *"lsym"* ]]
}

@test "lsym: detects a symlink in the current directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/real.txt"
    ln -s "$tmpdir/real.txt" "$tmpdir/link.txt"
    run nu --no-config-file -c "
        source '$AUTOLOAD/lsym.nu'
        cd '$tmpdir'
        lsym | get name | str join '\n'
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"link.txt"* ]]
}

# ---------------------------------------------------------------------------
# prefs (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "prefs: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/prefs.nu'"
    [ "$status" -eq 0 ]
}

@test "prefs: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/prefs.nu'; help prefs"
    [ "$status" -eq 0 ]
    [[ "$output" == *"prefs"* ]]
}

# ---------------------------------------------------------------------------
# displays (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "displays: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/displays.nu'"
    [ "$status" -eq 0 ]
}

@test "displays: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/displays.nu'; help displays"
    [ "$status" -eq 0 ]
    [[ "$output" == *"displays"* ]]
}

# ---------------------------------------------------------------------------
# apps (parse + help only; invokes find under /Applications)
# ---------------------------------------------------------------------------

@test "apps: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/apps.nu'"
    [ "$status" -eq 0 ]
}

@test "apps: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/apps.nu'; help apps"
    [ "$status" -eq 0 ]
    [[ "$output" == *"apps"* ]]
}

# ---------------------------------------------------------------------------
# fixperms (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "fixperms: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/fixperms.nu'"
    [ "$status" -eq 0 ]
}

@test "fixperms: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/fixperms.nu'; help fixperms"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fixperms"* ]]
}

# ---------------------------------------------------------------------------
# psync (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "psync: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/psync.nu'"
    [ "$status" -eq 0 ]
}

@test "psync: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/psync.nu'; help psync"
    [ "$status" -eq 0 ]
    [[ "$output" == *"psync"* ]]
}

@test "psync: dry-run message contains literal '(dry run)'" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    # rsync will fail finding nonexistent src but the print happens first
    run nu --no-config-file -c "
        source '$AUTOLOAD/psync.nu'
        psync '$tmpdir/src/' '$tmpdir/dst/'
    " 2>&1
    rm -rf "$tmpdir"
    # status may be nonzero (rsync src missing) but message must appear
    [[ "$output" == *"(dry run)"* ]]
}

# ---------------------------------------------------------------------------
# sha1
# ---------------------------------------------------------------------------

@test "sha1: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/sha1.nu'"
    [ "$status" -eq 0 ]
}

@test "sha1: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/sha1.nu'; help sha1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"sha1"* ]]
}

@test "sha1: hashes a known file" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    echo -n "" > "$tmpdir/empty.txt"
    run nu --no-config-file -c "
        source '$AUTOLOAD/sha1.nu'
        sha1 '$tmpdir/empty.txt'
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    # SHA1 of empty string is da39a3ee5e6b4b0d3255bfef95601890afd80709
    [[ "$output" == *"da39a3ee"* ]]
}

# ---------------------------------------------------------------------------
# tarball
# ---------------------------------------------------------------------------

@test "tarball: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/tarball.nu'"
    [ "$status" -eq 0 ]
}

@test "tarball: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/tarball.nu'; help tarball"
    [ "$status" -eq 0 ]
    [[ "$output" == *"tarball"* ]]
}

@test "tarball: creates a .tar.gz from a directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir "$tmpdir/mydir"
    touch "$tmpdir/mydir/file.txt"
    run nu --no-config-file -c "
        source '$AUTOLOAD/tarball.nu'
        cd '$tmpdir'
        tarball mydir
    "
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/mydir.tar.gz" ]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# deleted
# ---------------------------------------------------------------------------

@test "deleted: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/deleted.nu'"
    [ "$status" -eq 0 ]
}

@test "deleted: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/deleted.nu'; help deleted"
    [ "$status" -eq 0 ]
    [[ "$output" == *"deleted"* ]]
}

@test "deleted: reports a deleted file from git history" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" config commit.gpgsign false
    touch "$tmpdir/gone.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "add"
    git -C "$tmpdir" rm -q "$tmpdir/gone.txt"
    git -C "$tmpdir" commit -q -m "remove"
    run nu --no-config-file -c "
        source '$AUTOLOAD/deleted.nu'
        cd '$tmpdir'
        deleted
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"gone.txt"* ]]
}

# ---------------------------------------------------------------------------
# mirror (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "mirror: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/mirror.nu'"
    [ "$status" -eq 0 ]
}

@test "mirror: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/mirror.nu'; help mirror"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mirror"* ]]
}

# ---------------------------------------------------------------------------
# ours (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "ours: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ours.nu'"
    [ "$status" -eq 0 ]
}

@test "ours: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/ours.nu'; help ours"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ours"* ]]
}

# ---------------------------------------------------------------------------
# ref
# ---------------------------------------------------------------------------

@test "ref: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ref.nu'"
    [ "$status" -eq 0 ]
}

@test "ref: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/ref.nu'; help ref"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ref"* ]]
}

@test "ref: returns HEAD symbolic ref in a git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    git -C "$tmpdir" config commit.gpgsign false
    touch "$tmpdir/a.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "init"
    run nu --no-config-file -c "
        source '$AUTOLOAD/ref.nu'
        cd '$tmpdir'
        ref HEAD
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"refs/heads/"* ]]
}

# ---------------------------------------------------------------------------
# todo (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "todo: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/todo.nu'"
    [ "$status" -eq 0 ]
}

@test "todo: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/todo.nu'; help todo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"todo"* ]]
}

# ---------------------------------------------------------------------------
# brew_installed
# ---------------------------------------------------------------------------

@test "brew_installed: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_installed.nu'"
    [ "$status" -eq 0 ]
}

@test "brew_installed: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_installed.nu'; help brew_installed"
    [ "$status" -eq 0 ]
    [[ "$output" == *"brew_installed"* ]]
}

@test "brew_installed: reports installed for a known formula (git)" {
    command -v git &>/dev/null || skip "git not available"
    command -v brew &>/dev/null || skip "brew not available"
    brew list --formula git &>/dev/null || skip "git formula not installed"
    run nu --no-config-file -c "
        source '$AUTOLOAD/brew_installed.nu'
        brew_installed git
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"is installed"* ]]
}

@test "brew_installed: exits non-zero with message for uninstalled formula" {
    command -v brew &>/dev/null || skip "brew not available"
    run nu --no-config-file -c "
        source '$AUTOLOAD/brew_installed.nu'
        brew_installed __no_such_formula_xyz__
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"not installed"* ]]
}

# ---------------------------------------------------------------------------
# brew_deps
# ---------------------------------------------------------------------------

@test "brew_deps: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_deps.nu'"
    [ "$status" -eq 0 ]
}

@test "brew_deps: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/brew_deps.nu'; help brew_deps"
    [ "$status" -eq 0 ]
    [[ "$output" == *"brew_deps"* ]]
}

@test "brew_deps: runs without error (no args = all installed)" {
    command -v brew &>/dev/null || skip "brew not available"
    run nu --no-config-file -c "
        source '$AUTOLOAD/brew_deps.nu'
        brew_deps
    " 2>&1
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# swiftinfo (parse + help only)
# ---------------------------------------------------------------------------

@test "swiftinfo: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/swiftinfo.nu'"
    [ "$status" -eq 0 ]
}

@test "swiftinfo: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/swiftinfo.nu'; help swiftinfo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"swiftinfo"* ]]
}

# ---------------------------------------------------------------------------
# killsim (mutating — parse + help only)
# ---------------------------------------------------------------------------

@test "killsim: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/killsim.nu'"
    [ "$status" -eq 0 ]
}

@test "killsim: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/killsim.nu'; help killsim"
    [ "$status" -eq 0 ]
    [[ "$output" == *"killsim"* ]]
}

# ---------------------------------------------------------------------------
# restart (mutating — parse + help only; requires user_is_admin dep)
# ---------------------------------------------------------------------------

@test "restart: parse check with dependencies" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/restart.nu'
    "
    [ "$status" -eq 0 ]
}

@test "restart: help text is available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/restart.nu'
        help restart
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"restart"* ]]
}
