#!/usr/bin/env bats
# pi-functions.bats — Pi session wrapper tests across supported shells

load helpers/setup

setup() {
  fakebindir="$(mktemp -d)"
  cat >"$fakebindir/pi" <<'EOF'
#!/bin/sh
printf '%s\n' "$@"
EOF
  chmod +x "$fakebindir/pi"
}

teardown() {
  rm -rf "$fakebindir"
}

@test "zsh pic forwards arguments to pi --continue" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz pic
    pic --name "continue session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--continue\n--name\ncontinue session' ]
}

@test "zsh pir forwards arguments to pi --resume" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    rehash
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz pir
    pir --name "resume session"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--resume\n--name\nresume session' ]
}


@test "nushell pic forwards arguments to pi --continue" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/pic.nu'
    pic --name 'continue session'
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--continue\n--name\ncontinue session' ]
}

@test "nushell pir forwards arguments to pi --resume" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/pir.nu'
    pir --name 'resume session'
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--resume\n--name\nresume session' ]
}

@test "zsh pi-spark runs Pi with the Spark Qwen model" {
  run env PATH="$fakebindir:$PATH" zsh -c '
    fpath=("$HOME/.config/zsh/functions" $fpath)
    autoload -Uz pi-spark
    pi-spark
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'--provider\nspark\n--model\nInferact/Qwen3.8-27B-NVFP4' ]
}


@test "nushell pi-spark runs Pi with the Spark Qwen model" {
  run env PATH="$fakebindir:$PATH" nu --no-config-file -c "
    source '$HOME/.config/nushell/autoload/pi-spark.nu'
    pi-spark
  "

  [ "$status" -eq 0 ]
  [ "$output" = $'--provider\nspark\n--model\nInferact/Qwen3.8-27B-NVFP4' ]
}
