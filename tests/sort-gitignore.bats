#!/usr/bin/env bats
# sort-gitignore.bats — Functional tests for the sort-gitignore script

load helpers/setup

SCRIPT="$HOME/scripts/sort-gitignore"

@test "sort-gitignore: sorts lines alphabetically" {
  input=$'foo\nbar\nbaz'
  run bash -c "echo '$input' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "bar" ]
  [ "${lines[1]}" = "baz" ]
  [ "${lines[2]}" = "foo" ]
}

@test "sort-gitignore: negation override stays after its parent rule" {
  input=$'!.env.example\n.env'
  run bash -c "echo '$input' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = ".env" ]
  [ "${lines[1]}" = "!.env.example" ]
}

@test "sort-gitignore: deduplicates identical lines" {
  input=$'foo\nfoo\nbar'
  run bash -c "echo '$input' | '$SCRIPT'"
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
}

@test "sort-gitignore: current .gitignore is already sorted" {
  run bash -c "'$SCRIPT' < '$HOME/.gitignore' | diff - '$HOME/.gitignore'"
  [ "$status" -eq 0 ]
}
