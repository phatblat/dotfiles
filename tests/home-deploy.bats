#!/usr/bin/env bats
# home-deploy.bats — live-branch bookkeeping in .config/just/home.just
#
# home-deploy detaches the primary checkout at a ref and records the branch
# to return to; home-live switches back to it. The recipe resolves the primary
# checkout from its own repository context, so each test drives it against a
# throwaway clone that stands in for the primary checkout.

setup_clone() {
    CLONE="$BATS_TEST_TMPDIR/dotfiles"
    # A local clone hardlinks the object store instead of copying it, so each
    # test costs a working tree rather than a second copy of the whole repo.
    # --shared is faster still but leaves the clone dependent on the source's
    # object store, which git documents as a corruption risk.
    git clone -q "$BATS_TEST_DIRNAME/.." "$CLONE"
    git -C "$CLONE" config user.email "real@example.com"
    git -C "$CLONE" config user.name "Real User"
    git -C "$CLONE" config commit.gpgsign false
    # The clone inherits whatever the source checkout had: a local branch
    # when the source was on one, a detached HEAD when it was not (CI checks
    # out a merge ref). Create the branch explicitly so the test does not
    # depend on which of the two it got.
    git -C "$CLONE" switch -q -C main HEAD
    # The recipe refuses refs without the deploy spec and the post-checkout
    # hook; the clone already has both, so nothing else is needed here.
    git -C "$CLONE" branch feature1
}

# The branch home-deploy recorded, read from the clone's git path.
recorded_branch() {
    git -C "$CLONE" rev-parse --path-format=absolute --git-path dotfiles-live-branch
}

deploy() {
    run env HOME="$BATS_TEST_TMPDIR" \
        just --justfile "$CLONE/justfile" home-deploy "$1"
}

live() {
    run env HOME="$BATS_TEST_TMPDIR" \
        just --justfile "$CLONE/justfile" home-live
}

@test "home-deploy: records the branch it left so home-live can return to it" {
    setup_clone

    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(cat "$(recorded_branch)")" = "main" ]
}

@test "home-deploy: a second deploy keeps the originally recorded branch" {
    setup_clone

    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(cat "$(recorded_branch)")" = "main" ]

    # The checkout is now detached, so the second deploy records nothing and
    # the branch recorded by the first one must survive.
    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(cat "$(recorded_branch)")" = "main" ]
}

@test "home-deploy: a later deploy does not overwrite the branch home-live returns to" {
    setup_clone
    git -C "$CLONE" branch -q other
    git -C "$CLONE" switch -q other

    # The first deploy records the branch that was live before it detached
    # the checkout. A later deploy must not replace it, or home-live returns
    # to a branch the user never made live.
    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(cat "$(recorded_branch)")" = "other" ]

    # Move back onto a branch and deploy again: the recorded branch stands.
    git -C "$CLONE" switch -q main
    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(cat "$(recorded_branch)")" = "other" ]
}

@test "home-live: switches back to the recorded branch and clears the record" {
    setup_clone

    deploy feature1
    [ "$status" -eq 0 ]
    [ "$(git -C "$CLONE" branch --show-current)" = "" ]

    live
    [ "$status" -eq 0 ]
    [ "$(git -C "$CLONE" branch --show-current)" = "main" ]
    [ ! -f "$(recorded_branch)" ]
}

@test "home-live: refuses when no deploy is in effect" {
    setup_clone

    live
    [ "$status" -ne 0 ]
    [[ "$output" =~ "no home-deploy in effect" ]]
}

@test "home-deploy: refuses a ref without the deploy spec" {
    setup_clone
    git -C "$CLONE" branch --no-track empty-spec
    git -C "$CLONE" switch -q empty-spec
    rm "$CLONE/.config/mise/conf.d/dotfiles.toml"
    git -C "$CLONE" commit -qam "drop spec"
    git -C "$CLONE" switch -q main

    deploy empty-spec
    [ "$status" -ne 0 ]
    [[ "$output" =~ "has no .config/mise/conf.d/dotfiles.toml" ]]
}

@test "home-deploy: refuses a detached checkout with no recorded branch" {
    setup_clone
    # Detach the checkout without recording a live branch first. home-deploy
    # would have nowhere to send home-live, so it must refuse.
    git -C "$CLONE" checkout -q --detach HEAD

    deploy feature1
    [ "$status" -ne 0 ]
    [[ "$output" =~ "detached and no live branch is recorded" ]]
}

@test "home-deploy: refuses a ref without the post-checkout hook" {
    setup_clone
    git -C "$CLONE" branch --no-track empty-hook
    git -C "$CLONE" switch -q empty-hook
    rm "$CLONE/scripts/home-apply-hook"
    git -C "$CLONE" commit -qam "drop hook"
    git -C "$CLONE" switch -q main

    deploy empty-hook
    [ "$status" -ne 0 ]
    [[ "$output" =~ "has no scripts/home-apply-hook" ]]
}

@test "home-deploy: refuses a dirty primary checkout" {
    setup_clone
    echo "dirty" >> "$CLONE/.config/mise/conf.d/dotfiles.toml"

    deploy feature1
    [ "$status" -ne 0 ]
    [[ "$output" =~ "commit or stash the changes" ]]
}

@test "home-deploy: refuses a staged change in the primary checkout" {
    setup_clone
    echo "staged" >> "$CLONE/.config/mise/conf.d/dotfiles.toml"
    git -C "$CLONE" add -A

    deploy feature1
    [ "$status" -ne 0 ]
    [[ "$output" =~ "commit or stash the changes" ]]
}
