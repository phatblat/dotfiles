#!/usr/bin/env bats
# gemini-config-mask.bats - mask-gemini-config.sh (git clean filter for .gemini/config/config.json)
#
# The filter is `required = true`, so a non-zero exit breaks `git add`/`git status`.
# It blanks plugins.<name>.installedFrom.version and deletes top-level `sidecars`.
# MASK_GEMINI_SCRIPT lets a mutation check point the suite at a modified copy.

MASK="${MASK_GEMINI_SCRIPT:-${BATS_TEST_DIRNAME}/../scripts/mask-gemini-config.sh}"

@test "mask-gemini-config: blanks every installedFrom.version and keeps the rest" {
  run "$MASK" <<'EOF'
{"plugins":{
  "firebase":{"enabled":true,"installedFrom":{"id":"m/plugin/firebase","marketplace":"m","version":"1.0.0"}},
  "other":{"installedFrom":{"id":"m/plugin/other","version":"0.21.0"}}
}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.plugins.firebase.installedFrom.version == ""'
  echo "$output" | jq -e '.plugins.other.installedFrom.version == ""'
  echo "$output" | jq -e '.plugins.firebase.enabled == true and .plugins.firebase.installedFrom.id == "m/plugin/firebase"'
}

@test "mask-gemini-config: deletes sidecars" {
  run "$MASK" <<'EOF'
{"sidecars":{"proj-1":{"grants":["x"]}},"theme":{"primary":"#7AA2F7"}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'has("sidecars") | not'
  echo "$output" | jq -e '.theme.primary == "#7AA2F7"'
}

@test "mask-gemini-config: does not add a version key a plugin never had" {
  run "$MASK" <<'EOF'
{"plugins":{"p":{"installedFrom":{"id":"m/plugin/p"}},"q":{"enabled":false}}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.plugins.p.installedFrom | has("version") | not'
  echo "$output" | jq -e '.plugins.q == {enabled: false}'
}

@test "mask-gemini-config: a missing or non-object plugins key passes through unchanged" {
  for value in '"str"' '5' '[1,2]' 'null'; do
    run "$MASK" <<EOF
{"plugins":$value,"keep":1}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e --argjson v "$value" '.plugins == $v and .keep == 1'
  done

  run "$MASK" <<'EOF'
{"keep":1}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == {keep: 1}'
}

@test "mask-gemini-config: idempotent on its own output" {
  fixture='{"sidecars":{"a":1},"plugins":{"p":{"installedFrom":{"id":"i","version":"2.0.0"}}}}'

  once="$(printf '%s' "$fixture" | "$MASK")"
  twice="$(printf '%s' "$once" | "$MASK")"

  [ "$once" = "$twice" ]
}

@test "mask-gemini-config: empty stdin yields empty output and exit 0" {
  run "$MASK" < /dev/null

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "mask-gemini-config: invalid JSON exits non-zero" {
  run "$MASK" <<'EOF'
{not json
EOF

  [ "$status" -ne 0 ]
}

@test "mask-gemini-config: array-root input exits non-zero" {
  run "$MASK" <<'EOF'
[1,2]
EOF

  [ "$status" -ne 0 ]
}
