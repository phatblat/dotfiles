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
    autoload -Uz omp ompc
    ompc --name "continue session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--continue\n--name\ncontinue session' ]
}

@test "zsh ompr forwards arguments to omp --resume" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz omp ompr
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
    autoload -Uz omp cmt
    cmt
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\n/git:commit\n--model\nsmol\n--auto-approve' ]
}


@test "nushell cmt opens OMP commit workflow with no arguments" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/cmt.nu'
    cmt
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\n/git:commit\n--model\nsmol\n--auto-approve' ]
}

@test "zsh omp injects --allow-home" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz omp
    omp --print "hello"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "zsh omp leaves OMP_PROFILE to omp instead of passing --profile" {
  run env PATH="$fakebindir:$PATH" OMP_PROFILE=casper zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz omp
    omp --print "hello"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "zsh omp never duplicates --allow-home" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz omp
    omp --allow-home --print "hello"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "nushell omp injects --allow-home" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "source '$HOME/.config/nushell/autoload/omp.nu'; omp --print hello"

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "nushell omp leaves OMP_PROFILE to omp instead of passing --profile" {
  run env PATH="$fakebindir:$PATH" OMP_PROFILE=casper nu --no-config-file -c "source '$HOME/.config/nushell/autoload/omp.nu'; omp --print hello"

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "nushell omp never duplicates --allow-home" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "source '$HOME/.config/nushell/autoload/omp.nu'; omp --allow-home --print hello"

  [ "$status" -eq 0 ]
  [ "$output" = $'--allow-home\n--print\nhello' ]
}

@test "the omp wrapper owns --allow-home and session wrappers route through it" {
  # omp auto-switches to a temp dir when started in ~ unless --allow-home is
  # set, which would silently continue the wrong session in this repo.
  grep -q -- '--allow-home' "$HOME/.config/zsh/functions/omp"
  grep -q -- '--allow-home' "$HOME/.config/nushell/autoload/omp.nu"
  # OMP_DEFAULT_PROFILE is retired; omp reads OMP_PROFILE itself.
  ! grep -rq 'OMP_DEFAULT_PROFILE' "$HOME/.config/zsh/functions" "$HOME/.config/nushell/autoload" "$HOME/.bashrc" "$HOME/.env.example" "$HOME/scripts"
  for wrapper in ompc ompr; do
    ! grep -q -- '--allow-home' "$HOME/.config/zsh/functions/$wrapper"
    ! grep -q -- '--allow-home' "$HOME/.config/nushell/autoload/$wrapper.nu"
    grep -q -- '^omp --' "$HOME/.config/zsh/functions/$wrapper"
    grep -q -F 'source ~/.config/nushell/autoload/omp.nu' "$HOME/.config/nushell/autoload/$wrapper.nu"
  done
}
