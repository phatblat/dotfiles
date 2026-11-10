#!/usr/bin/env bats
# Verify is-dotfiles-checkout.sh across worktrees, nested dirs, and unrelated repos.

load helpers/setup

ROOT="$BATS_TEST_DIRNAME/.."
HELPER="$ROOT/scripts/is-dotfiles-checkout.sh"

make_repo() {
    git -C "$1" init -q
    git -C "$1" config user.email "test@example.com"
    git -C "$1" config user.name "Test User"
    git -C "$1" config commit.gpgsign false
    printf 'backing\n' > "$1/defaults.txt"
    git -C "$1" add defaults.txt
    git -C "$1" commit -qm "init"
}

@test "dotfiles helper: accepts worktree path with nested directories" {
    run "$HELPER" "$ROOT/.claude/hooks"
    [ "$status" -eq 0 ]

    nested="$ROOT/.claude/hooks/scripts"
    run "$HELPER" "$nested"
    [ "$status" -eq 0 ]

    run "$HELPER" "$ROOT"
    [ "$status" -eq 0 ]

    run "$HELPER"
    [ "$status" -eq 0 ]
}

@test "dotfiles helper: primary checkout root present" {
    run "$HELPER" "$HOME/dev/dotfiles"
    [ "$status" -eq 0 ]
}

@test "dotfiles helper: rejects the worktree that is only similar by name" {
    skip "a linked worktree with the same repository resolves to the same checkout; verify against the real paired worktree instead"
}

@test "dotfiles helper: rejects unrelated repositories, quoted paths, and non-git directories" {
    unrelated="$BATS_TEST_TMPDIR/unrelated-project"
    mkdir -p "$unrelated/sub dir"
    make_repo "$unrelated"
    run "$HELPER" "$unrelated"
    [ "$status" -eq 1 ]

    run "$HELPER" "$unrelated/sub dir"
    [ "$status" -eq 1 ]

    run "$HELPER" "/tmp"
    [ "$status" -eq 1 ]

    run "$HELPER" "$HOME"
    [ "$status" -eq 1 ]
}
