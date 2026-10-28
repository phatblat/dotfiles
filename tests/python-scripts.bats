#!/usr/bin/env bats
# python-scripts.bats - unit tests for standalone Python scripts under scripts/

load helpers/setup

@test "agy-plugins: lock, drift and install unit tests pass" {
  run python3 "${BATS_TEST_DIRNAME}/test_agy_plugins.py"

  [ "$status" -eq 0 ]
}

@test "cmux-settings: catalog, drift and fix unit tests pass" {
  run python3 "${BATS_TEST_DIRNAME}/test_cmux_settings.py"

  [ "$status" -eq 0 ]
}

@test "audit-ignored-config: assigned-credential rule unit tests pass" {
  run python3 "${BATS_TEST_DIRNAME}/test_audit_ignored_config.py"

  [ "$status" -eq 0 ]
}

@test "harness-sessions: usage labels, Pi session roots, OMP error classes and cd-prefix signal" {
  run python3 "${BATS_TEST_DIRNAME}/test_harness_sessions.py"

  [ "$status" -eq 0 ]
}

@test "flywheel: ledger privacy bound and worst-outcome collapse" {
  run python3 "${BATS_TEST_DIRNAME}/test_flywheel.py"

  [ "$status" -eq 0 ]
}
