#!/usr/bin/env bats
# omp-functions.bats — OMP session wrapper tests across supported shells

load helpers/setup

setup() {
  fakebindir="$(mktemp -d)"
  cat >"$fakebindir/omp" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
  chmod +x "$fakebindir/omp"
}

teardown() {
  rm -rf "$fakebindir"
}

@test "zsh ompc forwards arguments to omp --continue" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz ompc
    ompc --name "continue session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--continue\n--name\ncontinue session' ]
}

@test "zsh ompr forwards arguments to omp --resume" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz ompr
    ompr --name "resume session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--resume\n--name\nresume session' ]
}

@test "fish ompc forwards arguments to omp --continue" {
  run env PATH="$fakebindir:$PATH" fish --no-config -c '
    source "$HOME/.config/fish/functions/ompc.fish"
    ompc --name "continue session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--continue\n--name\ncontinue session' ]
}

@test "fish ompr forwards arguments to omp --resume" {
  run env PATH="$fakebindir:$PATH" fish --no-config -c '
    source "$HOME/.config/fish/functions/ompr.fish"
    ompr --name "resume session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--resume\n--name\nresume session' ]
}

@test "nushell ompc forwards arguments to omp --continue" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/ompc.nu'
    ompc --name 'continue session'
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--continue\n--name\ncontinue session' ]
}

@test "nushell ompr forwards arguments to omp --resume" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/ompr.nu'
    ompr --name 'resume session'
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--resume\n--name\nresume session' ]
}

@test "zsh cmt opens OMP commit workflow with no arguments" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz cmt
    cmt
  '

  [ "$status" -eq 0 ]
  [ "$output" = "/git:commit" ]
}

@test "fish cmt opens OMP commit workflow with no arguments" {
  run env PATH="$fakebindir:$PATH" fish --no-config -c '
    source "$HOME/.config/fish/functions/cmt.fish"
    cmt
  '

  [ "$status" -eq 0 ]
  [ "$output" = "/git:commit" ]
}

@test "nushell cmt opens OMP commit workflow with no arguments" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/cmt.nu'
    cmt
  "

  [ "$status" -eq 0 ]
  [ "$output" = "/git:commit" ]
}

@test "omp wrappers pass --allow-home so home-rooted sessions are not relocated" {
  # omp auto-switches to a temp dir when started in ~ unless --allow-home is
  # set, which would silently continue the wrong session in this repo.
  for wrapper in ompc ompr; do
    grep -q -- '--allow-home' "$HOME/.config/zsh/functions/$wrapper"
    grep -q -- '--allow-home' "$HOME/.config/fish/functions/$wrapper.fish"
    grep -q -- '--allow-home' "$HOME/.config/nushell/autoload/$wrapper.nu"
  done
}
