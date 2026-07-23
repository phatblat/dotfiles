#!/usr/bin/env bats
# sort-codex-config.bats — Regression tests for Codex config formatting

load helpers/setup

SCRIPT="$HOME/scripts/sort-codex-config.py"

@test "sort-codex-config: preserves Codex marketplace key order" {
  config="$BATS_TEST_TMPDIR/config.toml"
  cat > "$config" <<'EOF'
[marketplaces.example]
source = "https://example.test/marketplace.git"
source_type = "git"
last_revision = "abc123"
last_updated = "2026-07-22T00:00:00Z"
EOF

  run python3 "$SCRIPT" "$config"

  [ "$status" -eq 0 ]
  run sed -n '/^\[marketplaces.example\]/,$p' "$config"
  [ "$status" -eq 0 ]
  [ "${lines[1]}" = 'last_updated = "2026-07-22T00:00:00Z"' ]
  [ "${lines[2]}" = 'last_revision = "abc123"' ]
  [ "${lines[3]}" = 'source_type = "git"' ]
  [ "${lines[4]}" = 'source = "https://example.test/marketplace.git"' ]

  run python3 "$SCRIPT" --check "$config"
  [ "$status" -eq 0 ]
}
