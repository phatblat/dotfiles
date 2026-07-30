#!/usr/bin/env bash
# Claude model catalog: lockfile generation and drift/retirement checking.
#
# Current Claude model IDs (claude-opus-5, claude-sonnet-5, ...) carry no date
# suffix, so there is no version to pin in agent frontmatter. Instead we record
# what the live API reports into a tracked lockfile, so git history documents
# which model generation was in use and when it changed.
#
# The list endpoint under-reports usable IDs: older models appear only in dated
# form (claude-haiku-4-5-20251001) while their alias (claude-haiku-4-5) resolves
# and is what config usually cites, so aliases are probed and recorded too.
#
# Retirement data is NOT in the Models API -- it lives only in the deprecations
# doc, so we cross-reference both:
#   * absent from /v1/models          -> RETIRED (hard failure)
#   * listed Deprecated in the doc    -> warning, with days remaining
#
# Requires: curl, jq
#
#   claude-models.sh lock    # refresh .claude/models.lock
#   claude-models.sh check   # compare live API against the lockfile

set -euo pipefail

readonly API="https://api.anthropic.com/v1/models"
readonly DEPRECATIONS_URL="https://platform.claude.com/docs/en/about-claude/model-deprecations.md"
readonly LOCKFILE="${CLAUDE_MODELS_LOCK:-$HOME/.claude/models.lock}"

die() {
  printf 'claude-models: %s\n' "$*" >&2
  exit 1
}

# Resolve API credentials. Prefer explicit API keys, then exported OAuth tokens,
# then Claude Code's current macOS Keychain entry. Do not inspect the stale
# ~/.claude/.credentials.json file.
# Return 1 when Claude Code is logged in but no reusable token is available to
# shell scripts; callers may treat that as a non-fatal skip.
resolve_auth() {
  if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -f "$HOME/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$HOME/.env"
    set +a
  fi

  if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    AUTH_HEADER="x-api-key: $ANTHROPIC_API_KEY"
    BETA_HEADER="anthropic-version: 2023-06-01"
    return 0
  fi

  local token
  token="${ANTHROPIC_AUTH_TOKEN:-${CLAUDE_CODE_OAUTH_TOKEN:-}}"
  if [ -n "$token" ]; then
    AUTH_HEADER="Authorization: Bearer $token"
    BETA_HEADER="anthropic-beta: oauth-2025-04-20"
    return 0
  fi

  if command -v security >/dev/null 2>&1; then
    token=$(security find-generic-password -s "Claude Code-credentials" -a "${USER:-$(id -un)}" -w 2>/dev/null |
      jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null || true)
    if [ -n "$token" ]; then
      AUTH_HEADER="Authorization: Bearer $token"
      BETA_HEADER="anthropic-beta: oauth-2025-04-20"
      return 0
    fi
  fi

  if command -v claude >/dev/null 2>&1 && claude auth status --json 2>/dev/null | jq -e '.loggedIn == true' >/dev/null; then
    return 1
  fi

  die "no direct API credentials — set ANTHROPIC_API_KEY in ~/.env, export ANTHROPIC_AUTH_TOKEN, or log in to Claude Code"
}

# Fetch every model, following the after_id cursor. Emits the merged .data array.
fetch_models() {
  local page after='' all='[]' body status
  while :; do
    page=$(curl -sS --max-time 30 "$API?limit=100${after:+&after_id=$after}" \
      -H "$AUTH_HEADER" \
      -H "anthropic-version: 2023-06-01" \
      -H "$BETA_HEADER" \
      -w $'\n%{http_code}') || die "request to /v1/models failed (network or timeout)"

    status=${page##*$'\n'}
    body=${page%$'\n'*}

    case $status in
    2*) ;;
    401 | 403) die "HTTP $status — credentials rejected by /v1/models" ;;
    429) die "HTTP 429 — rate limited; retry shortly" ;;
    *) die "HTTP $status — $(printf '%s' "$body" | jq -r '.error.message // .' 2>/dev/null | head -c 200)" ;;
    esac

    all=$(printf '%s\n%s' "$all" "$body" | jq -s '.[0] + .[1].data')
    [ "$(printf '%s' "$body" | jq -r '.has_more')" = true ] || break
    after=$(printf '%s' "$body" | jq -r '.last_id')
  done
  printf '%s' "$all"
}

# Parse the deprecations doc's status table into TSV: id<TAB>state<TAB>retire_date
fetch_deprecations() {
  curl -sS --max-time 30 "$DEPRECATIONS_URL" 2>/dev/null |
    awk -F'|' '
      /^\| *claude-[a-z0-9.-]+ *\|/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        gsub(/^[ \t]+|[ \t]+$/, "", $3)
        gsub(/^[ \t]+|[ \t]+$/, "", $5)
        print $2 "\t" $3 "\t" $5
      }' || true
}

# Dateless alias for each dated model ID, as TSV: dated_id<TAB>alias.
# The list endpoint reports only the dated form (claude-haiku-4-5-20251001) even
# though the alias (claude-haiku-4-5) resolves and is what config usually cites,
# so probe each candidate and record the ones that answer. Models from Opus 4.6
# / Sonnet 4.6 on are already dateless and have no alias to derive.
resolve_aliases() {
  local id candidate
  printf '%s' "$1" | jq -r '.[].id' | while IFS= read -r id; do
    case $id in
    *-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) candidate=${id%-*} ;;
    *) continue ;;
    esac
    if model_is_live "$candidate"; then
      printf '%s\t%s\n' "$id" "$candidate"
    fi
  done
}

filter_active_models() {
  local models=$1 deprecations=$2
  printf '%s' "$models" | jq --arg deprecations "$deprecations" '
    ($deprecations | split("\n") | map(select(length > 0) | split("\t") | select(.[1] == "Deprecated") | .[0])) as $deprecated |
    map(select(.id as $id | $deprecated | index($id) | not))
  '
}

render_lock() {
  local models=$1 deprecations=$2 aliases=$3 generated=$4 out=$5
  {
    printf '# Claude model catalog — generated by scripts/claude-models.sh\n'
    printf '# Source: GET /v1/models + %s\n' "$DEPRECATIONS_URL"
    printf '# Regenerate: just update-models\n'
    printf '# generated: %s\n' "$generated"
    printf '#\n'
    printf '# %-28s %-20s %-10s %9s %8s  %s\n' id alias state ctx max_out retires
    printf '%s' "$models" | jq -r '.[] | [.id, (.max_input_tokens|tostring), (.max_tokens|tostring)] | @tsv' |
      sort |
      while IFS=$'\t' read -r id ctx maxout; do
        local state retires line alias
        line=$(printf '%s' "$deprecations" | awk -F'\t' -v m="$id" '$1 == m {print; exit}')
        state=$(printf '%s' "$line" | cut -f2)
        retires=$(printf '%s' "$line" | cut -f3)
        alias=$(printf '%s' "$aliases" | awk -F'\t' -v m="$id" '$1 == m {print $2; exit}')
        [ -n "$state" ] || state="Active"
        [ -n "$retires" ] || retires="unknown"
        [ -n "$alias" ] || alias="-"
        printf '  %-28s %-20s %-10s %9s %8s  %s\n' "$id" "$alias" "$state" "$ctx" "$maxout" "$retires"
      done
  } >"$out"
}

cmd_lock() {
  if ! resolve_auth; then
    die "Claude Code is logged in, but no direct API token is available to refresh $LOCKFILE — run claude setup-token or set ANTHROPIC_API_KEY"
  fi
  local models deprecations aliases generated
  models=$(fetch_models)
  deprecations=$(fetch_deprecations)
  models=$(filter_active_models "$models" "$deprecations")
  aliases=$(resolve_aliases "$models")
  generated=$(date -u +%Y-%m-%d)

  mkdir -p "$(dirname "$LOCKFILE")"
  render_lock "$models" "$deprecations" "$aliases" "$generated" "$LOCKFILE"

  printf 'Wrote %s (%s models, %s aliases)\n' \
    "$LOCKFILE" "$(printf '%s' "$models" | jq 'length')" "$(printf '%s' "$aliases" | grep -c . || true)"
}

# Model IDs assigned in tracked config — only structured `model:` / "model":
# fields, never prose, so a model named in a sentence is not a false positive.
# Bare tier keywords (sonnet, opus, haiku, inherit) are resolved by the harness,
# not the API, so they are skipped by requiring the claude-* prefix.
tracked_model_ids() {
  # No \b — git grep's ERE does not support it and silently matches nothing.
  # --untracked so a newly added agent is checked before it is committed;
  # it still honours .gitignore, so vendored plugin fixtures stay excluded.
  git -C "$HOME" grep --untracked -hoE '"?model"?: *"?(claude-[a-z]+-[0-9][a-z0-9-]*)' -- \
    '.claude/agents' '.claude/skills' '.claude/settings.json' '.codex/agents' 2>/dev/null |
    grep -oE 'claude-[a-z]+-[0-9][a-z0-9-]*' |
    sed 's/-*$//' |
    sort -u || true
}

# Resolve one model ID against the API. Aliases (claude-haiku-4-5) resolve even
# though the list endpoint reports only their dated form, so this is the
# authoritative liveness check — 200 = usable, 404 = retired or nonexistent.
model_is_live() {
  local status
  status=$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' \
    "$API/$1" \
    -H "$AUTH_HEADER" \
    -H "anthropic-version: 2023-06-01" \
    -H "$BETA_HEADER") || return 2
  [ "$status" = 200 ]
}

cmd_check() {
  if ! resolve_auth; then
    printf '  - Claude Code is logged in, but no direct API token is available; skipping live model check\n'
    printf '    Run `claude setup-token` or set ANTHROPIC_API_KEY to enable this check outside Claude Code.\n'
    return 0
  fi
  local models deprecations aliases live today rc=0
  models=$(fetch_models)
  deprecations=$(fetch_deprecations)
  models=$(filter_active_models "$models" "$deprecations")
  aliases=$(resolve_aliases "$models")
  live=$(printf '%s' "$models" | jq -r '.[].id' | sort)
  today=$(date -u +%s)

  # 1. Retirement / deprecation status of everything currently live.
  local id state retires retire_epoch days
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    state=$(printf '%s' "$deprecations" | awk -F'\t' -v m="$id" '$1 == m {print $2; exit}')
    retires=$(printf '%s' "$deprecations" | awk -F'\t' -v m="$id" '$1 == m {print $3; exit}')
    case $state in
    Deprecated)
      retire_epoch=$(date -j -f '%B %d, %Y' "$retires" +%s 2>/dev/null || echo 0)
      if [ "$retire_epoch" -gt 0 ]; then
        days=$(((retire_epoch - today) / 86400))
        printf '  ! %-28s DEPRECATED — retires %s (%s days)\n' "$id" "$retires" "$days"
      else
        printf '  ! %-28s DEPRECATED — retires %s\n' "$id" "$retires"
      fi
      ;;
    esac
  done <<<"$live"

  # 2. Model IDs referenced by tracked config but absent from the API = retired.
  local referenced
  referenced=$(tracked_model_ids)
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if ! model_is_live "$id"; then
      printf '  x %-28s RETIRED or unavailable — referenced in tracked config\n' "$id"
      rc=1
    fi
  done <<<"$referenced"

  # 3. Drift against the lockfile.
  if [ ! -f "$LOCKFILE" ]; then
    printf '  ? no lockfile at %s — run: just update-models\n' "$LOCKFILE"
    return "$rc"
  fi
  local tmp
  tmp=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  render_lock "$models" "$deprecations" "$aliases" \
    "$(awk '/^# generated:/{print $3}' "$LOCKFILE")" "$tmp"

  if diff -q <(grep -v '^# generated:' "$LOCKFILE") <(grep -v '^# generated:' "$tmp") >/dev/null; then
    printf '  ok %s models live, lockfile in sync\n' "$(printf '%s' "$live" | grep -c .)"
  else
    printf '  ~ lockfile drift — run: just update-models\n'
    # diff exits 1 when files differ; that is the expected path here, so don't
    # let `set -e` + pipefail abort before the return below.
    diff <(grep -v '^# generated:' "$LOCKFILE") <(grep -v '^# generated:' "$tmp") |
      grep -E '^[<>]' | sed 's/^/    /' || true
  fi

  # Only a retired model still referenced by tracked config is a hard failure;
  # deprecations and lockfile drift are informational so `just outdated` keeps going.
  return "$rc"
}

main() {
  case "${1:-}" in
  lock) cmd_lock ;;
  check) cmd_check ;;
  *) die "usage: claude-models.sh {lock|check}" ;;
  esac
}

main "$@"
