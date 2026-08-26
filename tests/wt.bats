#!/usr/bin/env bats
# wt.bats — Worktree branch-resolution tests

load helpers/setup

ZSH_WT="$HOME/.config/zsh/functions/wt"
NU_WT="$HOME/.config/nushell/autoload/wt.nu"

setup() {
  remote="$BATS_TEST_TMPDIR/remote.git"
  seed="$BATS_TEST_TMPDIR/seed"
  clone="$BATS_TEST_TMPDIR/clone"
  fake_home="$BATS_TEST_TMPDIR/home"
  branch="ben/dxo-204/codex-attribution"

  git init --bare -q "$remote"
  git init -q -b main "$seed"
  git -C "$seed" config user.email test@example.com
  git -C "$seed" config user.name Test
  printf 'main\n' > "$seed/README"
  git -C "$seed" add README
  git -C "$seed" commit -qm main
  git -C "$seed" remote add origin "$remote"
  git -C "$seed" push -qu origin main
  git clone -q "$remote" "$clone"
  git -C "$seed" switch -qc "$branch"
  printf 'remote branch\n' > "$seed/README"
  git -C "$seed" commit -qam remote
  remote_head=$(git -C "$seed" rev-parse HEAD)
  git -C "$seed" push -qu origin "$branch"
  mkdir -p "$fake_home"
}

# Turns fake_home into a minimal git repo so repo_root == $HOME for the
# dotfiles-worktree guard tests below.
init_dotfiles_home() {
  git init -q "$fake_home"
  git -C "$fake_home" config user.email test@example.com
  git -C "$fake_home" config user.name Test
  printf 'home\n' > "$fake_home/README"
  git -C "$fake_home" add README
  git -C "$fake_home" commit -qm home
}

@test "zsh wt fetches and tracks a newly available remote branch" {
  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt "$3"
  ' zsh "$ZSH_WT" "$clone" "$branch"

  [ "$status" -eq 0 ]
  worktree=$(git -C "$clone" worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { path = $2 }
    $0 == "branch refs/heads/" b { print path }
  ')
  [ "$(git -C "$worktree" rev-parse HEAD)" = "$remote_head" ]
  [ "$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" = "origin/$branch" ]
}

@test "nushell wt fetches and tracks a newly available remote branch" {
  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$clone'; wt '$branch'"

  [ "$status" -eq 0 ]
  worktree=$(git -C "$clone" worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { path = $2 }
    $0 == "branch refs/heads/" b { print path }
  ')
  [ "$(git -C "$worktree" rev-parse HEAD)" = "$remote_head" ]
  [ "$(git -C "$worktree" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}')" = "origin/$branch" ]
}

@test "nushell wt prunes stale worktree metadata before creating a worktree" {
  stale="$BATS_TEST_TMPDIR/stale"
  git -C "$clone" fetch -q origin "$branch"
  git -C "$clone" worktree add -q -b "$branch" "$stale" "origin/$branch"
  rm -rf "$stale"

  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$clone'; wt '$branch'"

  [ "$status" -eq 0 ]
  worktree=$(git -C "$clone" worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { path = $2 }
    $0 == "branch refs/heads/" b { print path }
  ')
  [ "$(git -C "$worktree" rev-parse HEAD)" = "$remote_head" ]
}

@test "zsh wt prunes stale worktree metadata before creating a worktree" {
  stale="$BATS_TEST_TMPDIR/stale"
  git -C "$clone" fetch -q origin "$branch"
  git -C "$clone" worktree add -q -b "$branch" "$stale" "origin/$branch"
  rm -rf "$stale"

  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt "$3"
  ' zsh "$ZSH_WT" "$clone" "$branch"

  [ "$status" -eq 0 ]
  worktree=$(git -C "$clone" worktree list --porcelain | awk -v b="$branch" '
    /^worktree / { path = $2 }
    $0 == "branch refs/heads/" b { print path }
  ')
  [ "$(git -C "$worktree" rev-parse HEAD)" = "$remote_head" ]
}

@test "nushell wt prunes stale entries before browsing worktrees" {
  stale="$BATS_TEST_TMPDIR/stale"
  fake_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nawk '\''END { print }'\''\n' > "$fake_bin/fzf"
  chmod +x "$fake_bin/fzf"
  git -C "$clone" fetch -q origin "$branch"
  git -C "$clone" worktree add -q -b "$branch" "$stale" "origin/$branch"
  rm -rf "$stale"

  run env HOME="$fake_home" PATH="$fake_bin:$PATH" nu -c "source '$NU_WT'; cd '$clone'; wt"

  [ "$status" -eq 0 ]
}

@test "zsh wt prunes stale entries before browsing worktrees" {
  stale="$BATS_TEST_TMPDIR/stale"
  fake_bin="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nawk '\''END { print }'\''\n' > "$fake_bin/fzf"
  chmod +x "$fake_bin/fzf"
  git -C "$clone" fetch -q origin "$branch"
  git -C "$clone" worktree add -q -b "$branch" "$stale" "origin/$branch"
  rm -rf "$stale"

  run env HOME="$fake_home" PATH="$fake_bin:$PATH" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt
  ' zsh "$ZSH_WT" "$clone"

  [ "$status" -eq 0 ]

}

@test "zsh wt refuses a plain invocation inside the dotfiles repo" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt "$3"
  ' zsh "$ZSH_WT" "$fake_home" "$dotfiles_branch"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--dotfiles"* ]]
}

@test "nushell wt refuses a plain invocation inside the dotfiles repo" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$fake_home'; wt '$dotfiles_branch'"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--dotfiles"* ]]
}

@test "zsh wt --dotfiles creates a registered worktree inside the dotfiles repo" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt --dotfiles "$3"
  ' zsh "$ZSH_WT" "$fake_home" "$dotfiles_branch"

  [ "$status" -eq 0 ]
  resolved_home=$(cd "$fake_home" && pwd -P)
  run git -C "$fake_home" worktree list --porcelain
  [[ "$output" == *"worktree $resolved_home/.worktrees/dotfiles/$dotfiles_branch"* ]]
}

@test "nushell wt --dotfiles creates a registered worktree inside the dotfiles repo" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$fake_home'; wt --dotfiles '$dotfiles_branch'"

  [ "$status" -eq 0 ]
  resolved_home=$(cd "$fake_home" && pwd -P)
  run git -C "$fake_home" worktree list --porcelain
  [[ "$output" == *"worktree $resolved_home/.worktrees/dotfiles/$dotfiles_branch"* ]]
}

@test "zsh wt --dotfiles errors when \$HOME is not a git repository" {
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt --dotfiles "$3"
  ' zsh "$ZSH_WT" "$BATS_TEST_TMPDIR" "$dotfiles_branch"

  [ "$status" -ne 0 ]
}

@test "nushell wt --dotfiles errors when \$HOME is not a git repository" {
  dotfiles_branch="dotfiles-branch"

  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$BATS_TEST_TMPDIR'; wt --dotfiles '$dotfiles_branch'"

  [ "$status" -ne 0 ]
}

@test "zsh wt --dotfiles refuses a non-empty unregistered worktree path" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"
  wt_path="$fake_home/.worktrees/dotfiles/$dotfiles_branch"
  mkdir -p "$wt_path"
  echo not-a-worktree > "$wt_path/marker"

  run env HOME="$fake_home" zsh -c '
    fpath=("${1:h}" $fpath)
    autoload -Uz wt
    z() { builtin cd "$1"; }
    cd "$2"
    wt --dotfiles "$3"
  ' zsh "$ZSH_WT" "$fake_home" "$dotfiles_branch"

  [ "$status" -ne 0 ]
  [ -f "$wt_path/marker" ]
}

@test "nushell wt --dotfiles refuses a non-empty unregistered worktree path" {
  init_dotfiles_home
  dotfiles_branch="dotfiles-branch"
  wt_path="$fake_home/.worktrees/dotfiles/$dotfiles_branch"
  mkdir -p "$wt_path"
  echo not-a-worktree > "$wt_path/marker"

  run env HOME="$fake_home" nu -c "source '$NU_WT'; cd '$fake_home'; wt --dotfiles '$dotfiles_branch'"

  [ "$status" -ne 0 ]
  [ -f "$wt_path/marker" ]
}