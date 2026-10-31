#!/usr/bin/env bats
# home-spec.bats — classification guard in scripts/home_spec.py check
#
# A tracked relative symlink that leaves the repo is deployed as a link to the
# repo's own link, which resolves against the wrong directory, so `check` must
# force it into OUT_OF_REPO/DANGLING.

load helpers/setup

SCRIPT="$BATS_TEST_DIRNAME/../scripts/home_spec.py"

setup() {
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email "real@example.com"
    git -C "$REPO" config user.name "Real User"
    git -C "$REPO" config commit.gpgsign false
    echo "set a" > "$REPO/.inputrc"
    ln -s .inputrc "$REPO/.inputrc-alias"
}

@test "home_spec check: accepts symlinks that stay inside the repo" {
    git -C "$REPO" add -A
    python3 "$SCRIPT" generate --repo "$REPO"

    run python3 "$SCRIPT" check --repo "$REPO"
    [ "$status" -eq 0 ]
}

@test "home_spec check: rejects a tracked relative symlink that leaves the repo" {
    ln -s ../outside "$REPO/escape"
    git -C "$REPO" add -A
    python3 "$SCRIPT" generate --repo "$REPO"

    run python3 "$SCRIPT" check --repo "$REPO"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "unclassified: tracked symlink escape" ]]
}

@test "home_spec check: allows an absolute symlink target" {
    ln -s /etc/hosts "$REPO/absolute"
    git -C "$REPO" add -A
    python3 "$SCRIPT" generate --repo "$REPO"

    run python3 "$SCRIPT" check --repo "$REPO"
    [ "$status" -eq 0 ]
}
