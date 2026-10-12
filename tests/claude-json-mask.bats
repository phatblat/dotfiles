#!/usr/bin/env bats
# claude-json-mask.bats - mask-claude-json.sh and mask-claude-desktop.sh (git clean filters)
#
# Both filters are `required = true`, so a non-zero exit breaks `git add`/`git status`.
# mask-claude-json.sh is an ALLOWLIST (top-level mcpServers + non-default project fields);
# mask-claude-desktop.sh is a DENYLIST on `preferences` (named keys plus any `*Latched`).
# The *_SCRIPT env vars let a mutation check point the suite at a modified copy.

MASK_JSON="${MASK_CLAUDE_JSON_SCRIPT:-${BATS_TEST_DIRNAME}/../scripts/mask-claude-json.sh}"
MASK_DESKTOP="${MASK_CLAUDE_DESKTOP_SCRIPT:-${BATS_TEST_DIRNAME}/../scripts/mask-claude-desktop.sh}"

# ---- mask-claude-json.sh ----------------------------------------------------

@test "mask-claude-json: drops a project holding only default values" {
  run "$MASK_JSON" <<'EOF'
{"projects":{"/p/empty":{"allowedTools":[],"mcpServers":{},"enableAllProjectMcpServers":false,"enabledMcpjsonServers":null}}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.projects == {}'
}

@test "mask-claude-json: drops a project that is itself {}" {
  run "$MASK_JSON" <<'EOF'
{"projects":{"/p/bare":{}}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.projects == {}'
}

@test "mask-claude-json: keeps a project with a real mcpServers entry" {
  run "$MASK_JSON" <<'EOF'
{"projects":{
  "/p/empty":{"mcpServers":{}},
  "/p/real":{"mcpServers":{"foo":{"command":"x","args":["a"]}},"allowedTools":[]}
}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.projects | keys == ["/p/real"]'
  echo "$output" | jq -e '.projects["/p/real"].mcpServers.foo.command == "x"'
  # default-valued sibling field is pruned from the kept project
  echo "$output" | jq -e '.projects["/p/real"] | has("allowedTools") | not'
}

@test "mask-claude-json: a lone non-default scalar/list field keeps the project" {
  run "$MASK_JSON" <<'EOF'
{"projects":{
  "/p/flag":{"enableAllProjectMcpServers":true},
  "/p/tools":{"allowedTools":["Bash"]}
}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.projects | keys == ["/p/flag","/p/tools"]'
  echo "$output" | jq -e '.projects["/p/flag"] == {enableAllProjectMcpServers: true}'
  echo "$output" | jq -e '.projects["/p/tools"] == {allowedTools: ["Bash"]}'
}

@test "mask-claude-json: strips non-allowlisted keys at top level and per project" {
  run "$MASK_JSON" <<'EOF'
{
  "userID":"secret","oauthAccount":{"email":"a@b"},"machineID":"m",
  "mcpServers":{"top":{"command":"t"}},
  "projects":{"/p/real":{
    "mcpServers":{"foo":{"command":"x"}},
    "lastSessionFirstPrompt":"verbatim prompt","lastCost":1.5
  }}
}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'keys == ["mcpServers","projects"]'
  echo "$output" | jq -e '.mcpServers.top.command == "t"'
  echo "$output" | jq -e '.projects["/p/real"] | keys == ["mcpServers"]'
  [[ "$output" != *"verbatim prompt"* ]]
  [[ "$output" != *"secret"* ]]
}

@test "mask-claude-json: missing mcpServers/projects yield empty objects" {
  run "$MASK_JSON" <<'EOF'
{"userID":"u"}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == {mcpServers: {}, projects: {}}'
}

@test "mask-claude-json: output is valid JSON with sorted keys" {
  run "$MASK_JSON" <<'EOF'
{"projects":{"/z":{"allowedTools":["b"]},"/a":{"allowedTools":["a"]}},"mcpServers":{"zz":{"command":"1"},"aa":{"command":"2"}}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e . > /dev/null
  echo "$output" | jq -e '(.projects | keys_unsorted) == ["/a","/z"]'
  echo "$output" | jq -e '(.mcpServers | keys_unsorted) == ["aa","zz"]'
}

@test "mask-claude-json: idempotent on its own output" {
  fixture='{"userID":"u","mcpServers":{"t":{"command":"c"}},"projects":{"/e":{"mcpServers":{}},"/r":{"mcpServers":{"f":{"command":"x"}},"enableAllProjectMcpServers":true,"cost":3}}}'

  once="$(printf '%s' "$fixture" | "$MASK_JSON")"
  twice="$(printf '%s' "$once" | "$MASK_JSON")"

  [ -n "$once" ]
  [ "$once" = "$twice" ]
}

@test "mask-claude-json: invalid JSON exits non-zero" {
  run "$MASK_JSON" <<'EOF'
{not json
EOF

  [ "$status" -ne 0 ]
}

# ---- mask-claude-desktop.sh -------------------------------------------------

@test "mask-claude-desktop: removes named denylist keys, keeps real preferences" {
  run "$MASK_DESKTOP" <<'EOF'
{"preferences":{
  "epitaxyPrefs":{"pane":1},"sidebarMode":"chat","floatingAtollActive":true,
  "coworkLegacyRootGrantsPruned":true,"coworkOnboardingResumeStep":2,
  "launchPreviewPersistedWorkspaces":[],"launchPreviewSessionScopedSessions":{},
  "keepAwakeEnabled":true,"coworkBrowserToolsEnabled":false
}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.preferences == {keepAwakeEnabled: true, coworkBrowserToolsEnabled: false}'
}

@test "mask-claude-desktop: removes *Latched suffix keys but keeps look-alikes" {
  run "$MASK_DESKTOP" <<'EOF'
{"preferences":{
  "fooLatched":true,"anotherLatched":1,
  "latched":true,"LatchedFoo":true,"fooLatchedX":true,"fooLatch":true,"keepAwakeEnabled":true
}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.preferences | (has("fooLatched") or has("anotherLatched")) | not'
  echo "$output" | jq -e '.preferences | keys == ["LatchedFoo","fooLatch","fooLatchedX","keepAwakeEnabled","latched"]'
}

@test "mask-claude-desktop: preferences null passes through, exit 0" {
  run "$MASK_DESKTOP" <<'EOF'
{"preferences":null,"other":1}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == {preferences: null, other: 1}'
}

@test "mask-claude-desktop: non-object preferences pass through unchanged, exit 0" {
  for value in '"str"' '5' '[1,2]' 'true'; do
    run "$MASK_DESKTOP" <<EOF
{"preferences":$value,"mcpServers":{"a":{"command":"c"}}}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e --argjson v "$value" '.preferences == $v and .mcpServers.a.command == "c"'
  done
}

@test "mask-claude-desktop: missing preferences key is left untouched, exit 0" {
  run "$MASK_DESKTOP" <<'EOF'
{"mcpServers":{"a":{"command":"c"}}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == {mcpServers: {a: {command: "c"}}}'
}

@test "mask-claude-desktop: does not prune empty values outside the denylist" {
  # The script is a pure denylist; unlike mask-claude-json it never drops defaults.
  run "$MASK_DESKTOP" <<'EOF'
{"preferences":{"emptyList":[],"emptyObj":{},"off":false,"nothing":null},"mcpServers":{}}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.preferences == {emptyList: [], emptyObj: {}, off: false, nothing: null}'
  echo "$output" | jq -e '.mcpServers == {}'
}

@test "mask-claude-desktop: preserves key order (no -S)" {
  run "$MASK_DESKTOP" <<'EOF'
{"zeta":1,"preferences":{"z":1,"a":2,"sidebarMode":"x"},"alpha":2}
EOF

  [ "$status" -eq 0 ]
  echo "$output" | jq -e 'keys_unsorted == ["zeta","preferences","alpha"]'
  echo "$output" | jq -e '.preferences | keys_unsorted == ["z","a"]'
}

@test "mask-claude-desktop: idempotent on its own output" {
  fixture='{"preferences":{"epitaxyPrefs":{},"fooLatched":true,"keepAwakeEnabled":true},"mcpServers":{"a":{"command":"c"}}}'

  once="$(printf '%s' "$fixture" | "$MASK_DESKTOP")"
  twice="$(printf '%s' "$once" | "$MASK_DESKTOP")"

  [ -n "$once" ]
  [ "$once" = "$twice" ]
  echo "$twice" | jq -e '.preferences == {keepAwakeEnabled: true}'
}

@test "mask-claude-desktop: empty stdin yields empty output and exit 0" {
  run "$MASK_DESKTOP" < /dev/null

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "mask-claude-desktop: invalid JSON exits non-zero" {
  run "$MASK_DESKTOP" <<'EOF'
{not json
EOF

  [ "$status" -ne 0 ]
}
