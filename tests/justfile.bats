#!/usr/bin/env bats
# Regression tests for justfile recipes that orchestrate external tools.

@test "upgrade-mise-tools-commit ignores tools without a version bump" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local home="$BATS_TEST_TMPDIR/home"
  local log="$BATS_TEST_TMPDIR/commands.log"

  mkdir -p "$bindir" "$home/.config/mise"

  cat >"$bindir/mise" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "outdated --bump --json" ]]; then
  printf '%s\n' '{"cargo:https://example.test/wookie":{"current":"rev:abc","bump":null}}'
  exit 0
fi
printf 'mise %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/mise"

  cat >"$bindir/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$COMMAND_LOG"
exit 1
EOF
  chmod +x "$bindir/git"

  run env HOME="$home" PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" upgrade-mise-tools-commit

  [ "$status" -eq 0 ]
  [[ "$output" == *"All tools are up to date"* ]]
  [ ! -e "$log" ]
}

@test "upgrade-mise-tools-commit attributes generated commits" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local home="$BATS_TEST_TMPDIR/home"
  local log="$BATS_TEST_TMPDIR/commands.log"

  mkdir -p "$bindir" "$home/.config/mise"
  touch "$home/.config/mise/config.toml"

  cat >"$bindir/mise" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "outdated --bump --json" ]]; then
  printf '%s\n' '{"npm:example":{"current":"1.0.0","bump":"1.1.0"}}'
  exit 0
fi
printf 'mise %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/mise"

  cat >"$bindir/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$COMMAND_LOG"
EOF
  chmod +x "$bindir/git"

  run env HOME="$home" PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" upgrade-mise-tools-commit

  [ "$status" -eq 0 ]
  grep -Fq "git commit -m chore: bump npm:example 1.0.0 → 1.1.0 -m Co-Authored-By: Codex <noreply@openai.com>" "$log"
}
