#!/usr/bin/env bash
# Exa search for coding agents — the single canonical implementation.
# Shared by Claude Code, Codex, and any other file-aware harness.
# Reference it by path or symlink; never copy it.
#
# Requires: curl, jq
#
#   exa.sh context "<query>" [--tokens N|dynamic]
#   exa.sh search  "<query>" [--type auto|instant|fast|deep-lite|deep|deep-reasoning]
#                            [--results N] [--domains a.com,b.com]
#                            [--exclude c.com] [--since YYYY-MM-DD] [--chars N]

set -euo pipefail

readonly API_BASE="https://api.exa.ai"

die() {
  printf 'exa: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
exa.sh — Exa search for coding agents. Requires curl and jq.

  exa.sh context "<query>" [--tokens N|dynamic]
  exa.sh search  "<query>" [--type auto|instant|fast|deep-lite|deep|deep-reasoning]
                           [--results N] [--domains a.com,b.com]
                           [--exclude c.com] [--since YYYY-MM-DD] [--chars N]

Try context first for code-shaped questions; fall through to search for
recency, provenance control, or when context comes back empty.
EOF
  exit "${1:-0}"
}

load_key() {
  if [ -z "${EXA_API_KEY:-}" ] && [ -f "$HOME/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$HOME/.env"
    set +a
  fi
  [ -n "${EXA_API_KEY:-}" ] ||
    die "EXA_API_KEY not set — add it to ~/.env or export it (https://dashboard.exa.ai/api-keys)"
}

# api <path> <json-body> -> response body on stdout, dies on non-2xx
api() {
  local path=$1 body=$2 resp status payload
  resp=$(curl -sS --max-time 60 -X POST "$API_BASE/$path" \
    -H "x-api-key: $EXA_API_KEY" \
    -H 'Content-Type: application/json' \
    -d "$body" \
    -w $'\n%{http_code}') || die "request to /$path failed (network or timeout)"

  status=${resp##*$'\n'}
  payload=${resp%$'\n'*}

  case $status in
  2*) printf '%s' "$payload" ;;
  401 | 403) die "HTTP $status — EXA_API_KEY was rejected. Check the key in ~/.env." ;;
  400 | 422) die "HTTP $status — bad request: $(err_detail "$payload")" ;;
  429) die "HTTP 429 — rate limited. Wait and retry, or reduce --results." ;;
  *) die "HTTP $status — $(err_detail "$payload")" ;;
  esac
}

err_detail() {
  printf '%s' "$1" | jq -r '.error // .message // .detail // tostring' 2>/dev/null |
    head -c 300 || printf '%s' "$1" | head -c 300
}

cmd_context() {
  local query=${1:-} tokens=5000
  [ -n "$query" ] || die 'usage: exa.sh context "<query>" [--tokens N|dynamic]'
  shift
  while [ $# -gt 0 ]; do
    case $1 in
    --tokens)
      tokens=${2:?--tokens needs a value}
      shift 2
      ;;
    *) die "unknown option for context: $1" ;;
    esac
  done

  local body
  if [ "$tokens" = "dynamic" ]; then
    body=$(jq -n --arg q "$query" '{query:$q, tokensNum:"dynamic"}')
  else
    case $tokens in
    '' | *[!0-9]*) die "--tokens must be a number (50-100000) or 'dynamic'" ;;
    esac
    body=$(jq -n --arg q "$query" --argjson t "$tokens" '{query:$q, tokensNum:$t}')
  fi

  local out
  out=$(api context "$body")

  printf '%s' "$out" | jq -r '
    "exa/context: \(.outputTokens // "?") output tokens, \(.resultsCount // "?") sources"' >&2

  local response
  response=$(printf '%s' "$out" | jq -r '.response // empty')
  if [ -z "$response" ]; then
    printf 'exa/context: empty response — consider falling back to: exa.sh search\n' >&2
  else
    printf '%s\n' "$response"
  fi
}

cmd_search() {
  local query=${1:-} type=auto results=10 domains='' exclude='' since='' chars=600
  [ -n "$query" ] || die 'usage: exa.sh search "<query>" [--type T] [--results N] [--domains a,b] [--exclude c] [--since YYYY-MM-DD] [--chars N]'
  shift
  while [ $# -gt 0 ]; do
    case $1 in
    --type)
      type=${2:?--type needs a value}
      shift 2
      ;;
    --chars)
      chars=${2:?--chars needs a value}
      shift 2
      ;;
    --results)
      results=${2:?--results needs a value}
      shift 2
      ;;
    --domains)
      domains=${2:?--domains needs a value}
      shift 2
      ;;
    --exclude)
      exclude=${2:?--exclude needs a value}
      shift 2
      ;;
    --since)
      since=${2:?--since needs a value}
      shift 2
      ;;
    *) die "unknown option for search: $1" ;;
    esac
  done

  case $type in
  auto | instant | fast | deep-lite | deep | deep-reasoning) ;;
  *) die "--type must be one of: auto instant fast deep-lite deep deep-reasoning" ;;
  esac
  case $results in
  '' | *[!0-9]*) die "--results must be a number (1-100)" ;;
  esac
  case $chars in
  '' | *[!0-9]*) die "--chars must be a number (per-result highlight cap)" ;;
  esac
  if [ -n "$since" ] && ! printf '%s' "$since" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    die "--since must be YYYY-MM-DD"
  fi

  local body
  body=$(jq -n \
    --arg q "$query" --arg type "$type" --argjson n "$results" --argjson chars "$chars" \
    --arg domains "$domains" --arg exclude "$exclude" --arg since "$since" \
    '{query:$q, type:$type, numResults:$n, contents:{highlights:{maxCharacters:$chars}}}
     + (if $domains == "" then {} else {includeDomains: ($domains|split(","))} end)
     + (if $exclude == "" then {} else {excludeDomains: ($exclude|split(","))} end)
     + (if $since   == "" then {} else {startPublishedDate: ($since + "T00:00:00.000Z")} end)')

  local out
  out=$(api search "$body")

  printf '%s' "$out" | jq -r '
    "exa/search: \(.results|length) results, type=\(if (.resolvedSearchType // "") == "" then "auto" else .resolvedSearchType end)"' >&2

  printf '%s' "$out" | jq -r '
    if (.results // [] | length) == 0 then
      "_No results. Drop filters before adding more constraints._"
    else
      [ .results[] |
        "## \(.title // .url)",
        "<\(.url)>" + (if .publishedDate then "  ·  published \(.publishedDate[0:10])" else "" end),
        ((.highlights // []) | map("> " + gsub("\\s+"; " ")) | join("\n>\n")),
        ""
      ] | flatten | join("\n")
    end'
}

main() {
  [ $# -gt 0 ] || usage 1
  local sub=$1
  shift
  case $sub in
  context)
    load_key
    cmd_context "$@"
    ;;
  search)
    load_key
    cmd_search "$@"
    ;;
  -h | --help | help) usage 0 ;;
  *) die "unknown subcommand '$sub' — expected 'context' or 'search'" ;;
  esac
}

main "$@"
