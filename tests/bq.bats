#!/usr/bin/env bats
# bq.bats — Functional tests for the bq zsh function

load helpers/setup

BQ_FN="$HOME/.config/zsh/functions/bq"

@test "bq: no args prints usage and exits 1" {
  run zsh --no-rcs "$BQ_FN"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "bq: no args shows jq_filter example" {
  run zsh --no-rcs "$BQ_FN"
  [[ "$output" == *"jq_filter"* ]]
}
