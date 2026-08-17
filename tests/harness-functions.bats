#!/usr/bin/env bats
# harness-functions.bats — agent-harnesses.py wrapper tests across supported shells

load helpers/setup

setup() {
  fakebindir="$(mktemp -d)"
  cat >"$fakebindir/python3" <<'EOF'
#!/bin/sh
shift
printf '%s\n' "$@"
EOF
  chmod +x "$fakebindir/python3"
}

teardown() {
  rm -rf "$fakebindir"
}

@test "zsh ha forwards arguments to agent-harnesses.py audit" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz ha
    ha --json
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'audit\n--json' ]
}

@test "zsh hc forwards arguments to agent-harnesses.py validate" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz hc
    hc
  '

  [ "$status" -eq 0 ]
  [ "$output" = "validate" ]
}

@test "zsh hg forwards arguments to agent-harnesses.py generate" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz hg
    hg --check
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'generate\n--check' ]
}

@test "nushell ha forwards arguments to agent-harnesses.py audit" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/ha.nu'
    ha --json
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'audit\n--json' ]
}

@test "nushell hc forwards arguments to agent-harnesses.py validate" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/hc.nu'
    hc
  "

  [ "$status" -eq 0 ]
  [ "$output" = "validate" ]
}

@test "nushell hg forwards arguments to agent-harnesses.py generate" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/hg.nu'
    hg --check
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'generate\n--check' ]
}
