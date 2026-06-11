#!/usr/bin/env bats
# nu-wave3-bundle.bats — Nushell port tests for wave-3 bundle cluster:
#   current_branch, git_inside_repo, git_repo_dirty, repeatchar,
#   git_bundle_create, bundle-pull

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# current_branch
# ---------------------------------------------------------------------------

@test "current_branch: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/current_branch.nu'"
    [ "$status" -eq 0 ]
}

@test "current_branch: returns branch name in dotfiles repo" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/current_branch.nu'
        cd '$HOME'
        current_branch
    "
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "current_branch: returns a non-empty string" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/current_branch.nu'
        cd '$HOME'
        current_branch | str length | into string
    "
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
}

# ---------------------------------------------------------------------------
# git_inside_repo
# ---------------------------------------------------------------------------

@test "git_inside_repo: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/git_inside_repo.nu'"
    [ "$status" -eq 0 ]
}

@test "git_inside_repo: returns true inside a git repo" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/git_inside_repo.nu'
        cd '$HOME'
        git_inside_repo | into string
    "
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "git_inside_repo: returns false outside a git repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/git_inside_repo.nu'
        cd '$tmpdir'
        git_inside_repo | into string
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "git_inside_repo: return value is a boolean" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/git_inside_repo.nu'
        cd '$HOME'
        git_inside_repo | describe
    "
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

# ---------------------------------------------------------------------------
# git_repo_dirty
# ---------------------------------------------------------------------------

@test "git_repo_dirty: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/git_repo_clean.nu'
        source '$AUTOLOAD/git_repo_dirty.nu'
    "
    [ "$status" -eq 0 ]
}

@test "git_repo_dirty: returns false in a clean repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "hello" > "$tmpdir/init.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "init"

    run nu --no-config-file -c "
        source '$AUTOLOAD/git_repo_clean.nu'
        source '$AUTOLOAD/git_repo_dirty.nu'
        cd '$tmpdir'
        git_repo_dirty | into string
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "git_repo_dirty: returns true in a dirty repo" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "hello" > "$tmpdir/init.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "init"
    echo "change" > "$tmpdir/init.txt"

    run nu --no-config-file -c "
        source '$AUTOLOAD/git_repo_clean.nu'
        source '$AUTOLOAD/git_repo_dirty.nu'
        cd '$tmpdir'
        git_repo_dirty | into string
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "git_repo_dirty: return value is a boolean" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "test@test.com"
    git -C "$tmpdir" config user.name "Test"
    echo "hello" > "$tmpdir/init.txt"
    git -C "$tmpdir" add .
    git -C "$tmpdir" commit -q -m "init"

    run nu --no-config-file -c "
        source '$AUTOLOAD/git_repo_clean.nu'
        source '$AUTOLOAD/git_repo_dirty.nu'
        cd '$tmpdir'
        git_repo_dirty | describe
    "
    rm -rf "$tmpdir"
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

# ---------------------------------------------------------------------------
# repeatchar
# ---------------------------------------------------------------------------

@test "repeatchar: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/repeatchar.nu'"
    [ "$status" -eq 0 ]
}

@test "repeatchar: default length is 80 dashes" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/repeatchar.nu'
        repeatchar '-'
    "
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 80 ]
}

@test "repeatchar: custom char and length" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/repeatchar.nu'
        repeatchar '=' 10
    "
    [ "$status" -eq 0 ]
    [ "$output" = "==========" ]
}

@test "repeatchar: empty char exits non-zero" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/repeatchar.nu'
        repeatchar ''
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# git_bundle_create — mutating: parse + help only
# ---------------------------------------------------------------------------

@test "git_bundle_create: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/git_bundle_create.nu'"
    [ "$status" -eq 0 ]
}

@test "git_bundle_create: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/git_bundle_create.nu'
        help git_bundle_create
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"bundle"* ]]
}

# ---------------------------------------------------------------------------
# bundle-pull — mutating: parse + help only
# ---------------------------------------------------------------------------

@test "bundle-pull: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/bundle-pull.nu'"
    [ "$status" -eq 0 ]
}

@test "bundle-pull: help text available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/bundle-pull.nu'
        help 'bundle-pull'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"bundle"* ]]
}
