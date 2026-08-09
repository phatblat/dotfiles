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

@test "list-claude-models prints lockfile model IDs" {
  local home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$home/.claude"
  cat >"$home/.claude/models.lock" <<'EOF'
# Claude model catalog
  claude-opus-5                 - Active
  claude-sonnet-5               - Active
EOF

  run env HOME="$home" just --justfile "$BATS_TEST_DIRNAME/../justfile" list-claude-models

  [ "$status" -eq 0 ]
  [ "$output" = $'claude-opus-5\nclaude-sonnet-5' ]
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


# Writes a fake `gh` into $1 whose `extension list` prints the tab-separated
# rows given on stdin, and which logs every other invocation to $COMMAND_LOG.
fake_gh() {
  local bindir="$1"
  mkdir -p "$bindir"
  cat >"$bindir/gh" <<EOF
#!/usr/bin/env bash
if [[ "\$1 \$2" == "extension list" ]]; then
  printf '%s' '$(cat)'
  exit 0
fi
printf 'gh %s\n' "\$*" >>"\$COMMAND_LOG"
EOF
  chmod +x "$bindir/gh"
}

@test "install-gh-extensions skips extensions already installed" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf 'gh aw\tgithub/gh-aw\tv0.85.4\n' | fake_gh "$bindir"
  printf 'github/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  [[ "$output" == *"github/gh-aw already installed"* ]]
  # No install was attempted, so the mock never logged anything.
  [ ! -e "$log" ]
}

@test "install-gh-extensions installs extensions missing from the list" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf 'gh aw\tgithub/gh-aw\tv0.85.4\n' | fake_gh "$bindir"
  printf 'github/gh-aw\nmislav/gh-branch\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  grep -Fqx "gh extension install mislav/gh-branch" "$log"
  # The already-installed one must not be reinstalled.
  ! grep -Fq "github/gh-aw" "$log"
}

@test "install-gh-extensions ignores comments and blank lines" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  printf '' | fake_gh "$bindir"
  printf '# a comment\n\ngithub/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  [ "$(wc -l <"$log")" -eq 1 ]
  grep -Fqx "gh extension install github/gh-aw" "$log"
}

@test "install-gh-extensions does not treat a repo prefix as installed" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"
  local manifest="$BATS_TEST_TMPDIR/extensions.txt"

  # `github/gh-aw` is a substring of the installed `github/gh-aw-extras`,
  # so a non-anchored match would wrongly report it as already installed.
  printf 'gh aw-extras\tgithub/gh-aw-extras\tv1.0.0\n' | fake_gh "$bindir"
  printf 'github/gh-aw\n' >"$manifest"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$manifest" install-gh-extensions

  [ "$status" -eq 0 ]
  grep -Fqx "gh extension install github/gh-aw" "$log"
}

@test "install-gh-extensions is a no-op when the manifest is missing" {
  local bindir="$BATS_TEST_TMPDIR/bin"
  local log="$BATS_TEST_TMPDIR/commands.log"

  printf '' | fake_gh "$bindir"

  run env PATH="$bindir:$PATH" COMMAND_LOG="$log" \
    just --justfile "$BATS_TEST_DIRNAME/../justfile" \
    --set gh_extensions_manifest "$BATS_TEST_TMPDIR/absent.txt" install-gh-extensions

  [ "$status" -eq 0 ]
  [ ! -e "$log" ]
}