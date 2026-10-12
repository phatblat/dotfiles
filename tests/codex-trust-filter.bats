#!/usr/bin/env bats
# codex-trust-filter.bats - mask-codex-state.sh (clean) and restore-codex-trust.sh (smudge)
#
# The codex-config filter is `required = true`, so a smudge failure breaks
# `git checkout`, and a lost trust hash makes Codex mark every hook untrusted.
# Every test isolates the machine-local cache in $BATS_TEST_TMPDIR.

MASK="${BATS_TEST_DIRNAME}/../scripts/mask-codex-state.sh"
RESTORE="${BATS_TEST_DIRNAME}/../scripts/restore-codex-trust.sh"

setup() {
  export CODEX_HOOK_TRUST_CACHE="$BATS_TEST_TMPDIR/state/codex-hook-trust.tsv"
  ZERO="sha256:0000000000000000000000000000000000000000000000000000000000000000"
  HASH_A="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  HASH_B="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
}

# hook_state <key> <hash>: one [hooks.state."<key>"] table, as Codex writes it.
hook_state() {
  printf '[hooks.state."%s"]\ntrusted_hash = "%s"\n' "$1" "$2"
}

@test "mask: replaces a real hook hash with the zero sentinel" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" > "$BATS_TEST_TMPDIR/in.toml"

  run "$MASK" < "$BATS_TEST_TMPDIR/in.toml"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trusted_hash = \"$ZERO\""* ]]
  [[ "$output" != *"$HASH_A"* ]]
}

@test "mask then restore: the real hash survives the checkout round trip" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" > "$BATS_TEST_TMPDIR/in.toml"

  "$MASK" < "$BATS_TEST_TMPDIR/in.toml" > "$BATS_TEST_TMPDIR/blob.toml"
  "$RESTORE" < "$BATS_TEST_TMPDIR/blob.toml" > "$BATS_TEST_TMPDIR/out.toml"

  cmp "$BATS_TEST_TMPDIR/in.toml" "$BATS_TEST_TMPDIR/out.toml"
}

@test "mask: cleaning one file keeps the hashes recorded from another" {
  # config.toml and *.config.toml share one cache but carry different hook keys.
  hook_state "hooks.json:pre_tool_use:4:0" "$HASH_B" > "$BATS_TEST_TMPDIR/casper.toml"
  hook_state "hooks.json:stop:0:0" "$HASH_A" > "$BATS_TEST_TMPDIR/main.toml"

  "$MASK" < "$BATS_TEST_TMPDIR/casper.toml" > "$BATS_TEST_TMPDIR/casper.blob"
  "$MASK" < "$BATS_TEST_TMPDIR/main.toml" > "$BATS_TEST_TMPDIR/main.blob"

  "$RESTORE" < "$BATS_TEST_TMPDIR/casper.blob" > "$BATS_TEST_TMPDIR/casper.out"
  "$RESTORE" < "$BATS_TEST_TMPDIR/main.blob" > "$BATS_TEST_TMPDIR/main.out"
  cmp "$BATS_TEST_TMPDIR/casper.toml" "$BATS_TEST_TMPDIR/casper.out"
  cmp "$BATS_TEST_TMPDIR/main.toml" "$BATS_TEST_TMPDIR/main.out"
}

@test "mask: a sentinel in the input never overwrites a recorded real hash" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" | "$MASK" > /dev/null
  hook_state "hooks.json:stop:0:0" "$ZERO" > "$BATS_TEST_TMPDIR/blob.toml"

  "$MASK" < "$BATS_TEST_TMPDIR/blob.toml" > /dev/null
  run "$RESTORE" < "$BATS_TEST_TMPDIR/blob.toml"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trusted_hash = \"$HASH_A\""* ]]
}

@test "mask: a newer real hash replaces the recorded one" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" | "$MASK" > /dev/null
  hook_state "hooks.json:stop:0:0" "$HASH_B" | "$MASK" > /dev/null

  run bash -c '"$1" < <(printf "[hooks.state.\"hooks.json:stop:0:0\"]\ntrusted_hash = \"%s\"\n" "$2")' _ "$RESTORE" "$ZERO"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trusted_hash = \"$HASH_B\""* ]]
}

@test "restore: a hash is only applied to the exact hook key it was recorded for" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" | "$MASK" > /dev/null
  # hooks.json changed shape: the same slot is now a different handler key.
  hook_state "hooks.json:stop:1:0" "$ZERO" > "$BATS_TEST_TMPDIR/blob.toml"

  run "$RESTORE" < "$BATS_TEST_TMPDIR/blob.toml"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trusted_hash = \"$ZERO\""* ]]
  [[ "$output" != *"$HASH_A"* ]]
}

@test "restore: leaves non-hook tables and values untouched" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" | "$MASK" > /dev/null
  printf '[plugins."x"]\ntrusted_hash = "%s"\nname = "keep"\n' "$ZERO" > "$BATS_TEST_TMPDIR/blob.toml"

  run "$RESTORE" < "$BATS_TEST_TMPDIR/blob.toml"

  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$BATS_TEST_TMPDIR/blob.toml")" ]
}

@test "restore: a missing cache degrades to cat and exits 0" {
  # The smudge filter is required: any failure here breaks `git checkout`.
  hook_state "hooks.json:stop:0:0" "$ZERO" > "$BATS_TEST_TMPDIR/blob.toml"
  [ ! -e "$CODEX_HOOK_TRUST_CACHE" ]

  run "$RESTORE" < "$BATS_TEST_TMPDIR/blob.toml"

  [ "$status" -eq 0 ]
  [ "$output" = "$(cat "$BATS_TEST_TMPDIR/blob.toml")" ]
}

@test "mask: an unwritable cache never fails the filter or skips masking" {
  # `capture` is best effort: if it failed the filter, `git status` would break.
  : > "$BATS_TEST_TMPDIR/not-a-dir"
  export CODEX_HOOK_TRUST_CACHE="$BATS_TEST_TMPDIR/not-a-dir/cache.tsv"
  hook_state "hooks.json:stop:0:0" "$HASH_A" > "$BATS_TEST_TMPDIR/in.toml"

  run "$MASK" < "$BATS_TEST_TMPDIR/in.toml"

  [ "$status" -eq 0 ]
  [[ "$output" == *"trusted_hash = \"$ZERO\""* ]]
}

@test "mask: leaves the cache file untouched when nothing changed" {
  hook_state "hooks.json:stop:0:0" "$HASH_A" > "$BATS_TEST_TMPDIR/in.toml"
  "$MASK" < "$BATS_TEST_TMPDIR/in.toml" > /dev/null
  before=$(stat -f %i "$CODEX_HOOK_TRUST_CACHE" 2> /dev/null || stat -c %i "$CODEX_HOOK_TRUST_CACHE")

  "$MASK" < "$BATS_TEST_TMPDIR/in.toml" > /dev/null

  after=$(stat -f %i "$CODEX_HOOK_TRUST_CACHE" 2> /dev/null || stat -c %i "$CODEX_HOOK_TRUST_CACHE")
  [ "$before" = "$after" ]
}
