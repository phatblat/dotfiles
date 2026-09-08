#!/usr/bin/env bats
# check-symlinks.bats — Tests for scripts/check-symlinks.sh

load helpers/setup

SCRIPT="$HOME/scripts/check-symlinks.sh"

setup_test_repo() {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "real@example.com"
    git -C "$tmpdir" config user.name "Real User"
    git -C "$tmpdir" config commit.gpgsign false
    echo "tracked" > "$tmpdir/tracked.txt"
    git -C "$tmpdir" add tracked.txt
    git -C "$tmpdir" commit -qm "init"
    echo "$tmpdir"
}

@test "check-symlinks: rejects an absolute target pointing at tracked content" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    ln -s "$tmpdir/tracked.txt" "$tmpdir/link"

    run bash -c "cd '$tmpdir' && HOME='$tmpdir' '$SCRIPT' link"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "absolute targets" ]]

    rm -rf "$tmpdir"
}

@test "check-symlinks: accepts an absolute target outside the repo" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    ln -s /usr/bin/true "$tmpdir/link"

    run bash -c "cd '$tmpdir' && HOME='$tmpdir' '$SCRIPT' link"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}

@test "check-symlinks: accepts a relative target inside the repo" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    ln -s tracked.txt "$tmpdir/link"

    run bash -c "cd '$tmpdir' && HOME='$tmpdir' '$SCRIPT' link"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}
