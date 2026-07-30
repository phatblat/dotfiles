#!/usr/bin/env bats

load helpers/setup

SCRIPT="$HOME/scripts/claude-models.sh"

@test "claude-models: ignores stale OAuth expiresAt preflight" {
  local tmpdir bindir
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$tmpdir/.claude" "$bindir"

  cat > "$tmpdir/.claude/.credentials.json" <<'JSON'
{
  "claudeAiOauth": {
    "accessToken": "stale-file-token",
    "expiresAt": 1
  }
}
JSON

  cat > "$bindir/curl" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *"/v1/models?"*)
    printf '{"data":[],"has_more":false,"last_id":null}\n200'
    ;;
  *"model-deprecations.md"*)
    printf ''
    ;;
  *)
    printf 'unexpected curl invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$bindir/curl"

  run env \
    HOME="$tmpdir" \
    PATH="$bindir:$PATH" \
    CLAUDE_CODE_OAUTH_TOKEN="fresh-exported-token" \
    CLAUDE_MODELS_LOCK="$tmpdir/.claude/models.lock" \
    "$SCRIPT" check
  rm -rf "$tmpdir"

  [ "$status" -eq 0 ]
  [[ "$output" != *"OAuth token expired"* ]]
}

@test "claude-models: lock omits deprecated models" {
  local tmpdir bindir lockfile
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  lockfile="$tmpdir/.claude/models.lock"
  mkdir -p "$tmpdir/.claude" "$bindir"

  cat > "$bindir/curl" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *"/v1/models/claude-opus-4-1"*)
    printf 'not found'
    exit 0
    ;;
  *"/v1/models?"*)
    printf '{"data":[{"id":"claude-opus-4-1-20250805","max_input_tokens":200000,"max_tokens":32000},{"id":"claude-sonnet-5","max_input_tokens":1000000,"max_tokens":128000}],"has_more":false,"last_id":null}\n200'
    ;;
  *"model-deprecations.md"*)
    printf '| Model | Status | Replaced By | Deprecation Date | Retirement Date |\n'
    printf '| claude-opus-4-1-20250805 | Deprecated | claude-opus-4-5-20251101 | July 28, 2026 | August 5, 2026 |\n'
    ;;
  *)
    printf 'unexpected curl invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$bindir/curl"

  run env \
    HOME="$tmpdir" \
    PATH="$bindir:$PATH" \
    ANTHROPIC_API_KEY="test-key" \
    CLAUDE_MODELS_LOCK="$lockfile" \
    "$SCRIPT" lock
  local output_copy="$output"
  local status_copy="$status"
  local lock_contents="$(cat "$lockfile" 2>/dev/null || true)"
  rm -rf "$tmpdir"

  [ "$status_copy" -eq 0 ]
  [[ "$output_copy" == *"(1 models"* ]]
  [[ "$lock_contents" == *"claude-sonnet-5"* ]]
  [[ "$lock_contents" != *"claude-opus-4-1-20250805"* ]]
}

@test "claude-models: uses Claude Code keychain credentials" {
  local tmpdir bindir
  tmpdir="$(mktemp -d)"
  bindir="$tmpdir/bin"
  mkdir -p "$tmpdir/.claude" "$bindir"

  cat > "$bindir/security" <<'SH'
#!/usr/bin/env bash
if [ "$1" = "find-generic-password" ] && [ "$2" = "-s" ] && [ "$3" = "Claude Code-credentials" ]; then
  printf '{"claudeAiOauth":{"accessToken":"keychain-token","expiresAt":9999999999999}}\n'
  exit 0
fi
exit 1
SH
  chmod +x "$bindir/security"

  cat > "$bindir/curl" <<'SH'
#!/usr/bin/env bash
case "$*" in
  *"/v1/models?"*)
    [[ "$*" == *"Authorization: Bearer keychain-token"* ]] || exit 1
    printf '{"data":[],"has_more":false,"last_id":null}\n200'
    ;;
  *"model-deprecations.md"*)
    printf ''
    ;;
  *)
    printf 'unexpected curl invocation: %s\n' "$*" >&2
    exit 1
    ;;
esac
SH
  chmod +x "$bindir/curl"

  run env HOME="$tmpdir" PATH="$bindir:$PATH" CLAUDE_MODELS_LOCK="$tmpdir/.claude/models.lock" "$SCRIPT" check
  rm -rf "$tmpdir"

  [ "$status" -eq 0 ]
  [[ "$output" != *"skipping live model check"* ]]
}
