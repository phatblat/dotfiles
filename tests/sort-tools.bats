#!/usr/bin/env bats
# sort-tools.bats — Functional tests for scripts/sort-tools.py

load helpers/setup

SCRIPT="${BATS_TEST_DIRNAME}/../scripts/sort-tools.py"

setup() {
  CONFIG="$(mktemp "${BATS_TEST_TMPDIR}/config.XXXXXX")"
}

@test "sort-tools: sorts single-line entries alphabetically" {
  printf '[tools]\nzed = "1"\nalpha = "2"\n' >"$CONFIG"
  run python3 "$SCRIPT" "$CONFIG"
  [ "$status" -eq 0 ]
  [ "$(sed -n 2p "$CONFIG")" = 'alpha = "2"' ]
  [ "$(sed -n 3p "$CONFIG")" = 'zed = "1"' ]
}

@test "sort-tools: keeps multi-line inline tables intact when sorting" {
  cat >"$CONFIG" <<'EOF'
[tools]
zed = "1"
claude = {
  version = "2",
  allow_builds = ["a", "b"],
}
alpha = "3"
EOF
  run python3 "$SCRIPT" "$CONFIG"
  [ "$status" -eq 0 ]
  expected=$'[tools]\nalpha = "3"\nclaude = {\n  version = "2",\n  allow_builds = ["a", "b"],\n}\nzed = "1"'
  [ "$(cat "$CONFIG")" = "$expected" ]
}

@test "sort-tools: brackets inside quotes and trailing comments do not unbalance entries" {
  cat >"$CONFIG" <<'EOF'
[tools]
zed = { version = "1", note = "has [bracket" } # trailing ] comment {
alpha = "2"
EOF
  run python3 "$SCRIPT" "$CONFIG"
  [ "$status" -eq 0 ]
  [ "$(sed -n 2p "$CONFIG")" = 'alpha = "2"' ]
  [[ "$(sed -n 3p "$CONFIG")" == zed* ]]
}

@test "sort-tools: --check passes on sorted multi-line input and fails on unsorted" {
  printf '[tools]\nalpha = {\n  version = "1",\n}\nzed = "2"\n' >"$CONFIG"
  run python3 "$SCRIPT" --check "$CONFIG"
  [ "$status" -eq 0 ]

  printf '[tools]\nzed = "2"\nalpha = {\n  version = "1",\n}\n' >"$CONFIG"
  run python3 "$SCRIPT" --check "$CONFIG"
  [ "$status" -eq 1 ]
}

@test "sort-tools: --check passes on the repo mise config" {
  run python3 "$SCRIPT" --check "${BATS_TEST_DIRNAME}/../.config/mise/config.toml"
  [ "$status" -eq 0 ]
}
