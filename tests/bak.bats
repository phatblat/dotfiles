#!/usr/bin/env bats
# bak.bats — Functional tests for the bak zsh function

load helpers/setup

BAK_FN="$HOME/.config/zsh/functions/bak"

setup() {
  TEST_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "bak: adds .bak extension to file" {
  touch "$TEST_DIR/notes.md"
  run zsh --no-rcs "$BAK_FN" "$TEST_DIR/notes.md"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/notes.md.bak" ]
  [ ! -f "$TEST_DIR/notes.md" ]
}

@test "bak: removes .bak extension from .bak file" {
  touch "$TEST_DIR/notes.md.bak"
  run zsh --no-rcs "$BAK_FN" "$TEST_DIR/notes.md.bak"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/notes.md" ]
  [ ! -f "$TEST_DIR/notes.md.bak" ]
}

@test "bak: exits 1 for nonexistent file" {
  run zsh --no-rcs "$BAK_FN" "$TEST_DIR/ghost.txt"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "bak: handles directory" {
  mkdir "$TEST_DIR/config"
  run zsh --no-rcs "$BAK_FN" "$TEST_DIR/config"
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/config.bak" ]
  [ ! -d "$TEST_DIR/config" ]
}

@test "bak: strips trailing slash from directory" {
  mkdir "$TEST_DIR/config"
  run zsh --no-rcs "$BAK_FN" "$TEST_DIR/config/"
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR/config.bak" ]
}
