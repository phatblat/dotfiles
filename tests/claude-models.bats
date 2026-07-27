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
    "accessToken": "test-access-token",
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

  run env HOME="$tmpdir" PATH="$bindir:$PATH" CLAUDE_MODELS_LOCK="$tmpdir/.claude/models.lock" "$SCRIPT" check
  rm -rf "$tmpdir"

  [ "$status" -eq 0 ]
  [[ "$output" != *"OAuth token expired"* ]]
}
