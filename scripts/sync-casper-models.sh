#!/usr/bin/env bash
# Sync Casper model metadata from live APIs into OMP profile config.
#
# Sources:
#   - Casper /v1/models: model IDs, context windows, reasoning metadata
#   - Baseten pricing page: per-1M-token costs (scraped via r.jina.ai)
#
# Output:
#   - ~/.omp/profiles/casper/agent/models.yml (merged)
#   - ~/.omp/profiles/casper/agent/config.yml (enabledModels updated if requested)
#
# Usage:
#   sync-casper-models.sh [--update-enabled] [--dry-run]
#
# Options:
#   --update-enabled   Also update config.yml enabledModels to match catalog
#   --dry-run          Print changes without writing files
#   -h, --help         Show this help

set -euo pipefail

OMP_PROFILE_DIR="${OMP_PROFILE_DIR:-$HOME/.omp/profiles/casper/agent}"
MODELS_YML="$OMP_PROFILE_DIR/models.yml"
CONFIG_YML="$OMP_PROFILE_DIR/config.yml"
CASPER_API_KEY="${CASPER_API_KEY:-}"
BASETEN_PRICING_URL="https://r.jina.ai/http://www.baseten.co/pricing"

UPDATE_ENABLED=false
DRY_RUN=false

log() { printf '%s\n' "$*" >&2; }
die() { log "error: $*"; exit 1; }
usage() { sed -n '1,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update-enabled) UPDATE_ENABLED=true; shift ;;
    --dry-run)        DRY_RUN=true; shift ;;
    -h|--help)        usage; exit 0 ;;
    *)                die "unknown option: $1" ;;
  esac
done

[[ -n "$CASPER_API_KEY" ]] || die "CASPER_API_KEY is not set"
[[ -f "$MODELS_YML" ]] || die "models.yml not found at $MODELS_YML"
[[ -f "$CONFIG_YML" ]] || die "config.yml not found at $CONFIG_YML"

# --- Fetch Casper catalog ---------------------------------------------------
log "Fetching Casper catalog..."
CASPER_JSON=$(curl -sf -H "Authorization: Bearer $CASPER_API_KEY" \
  "https://casper-api.ditto.live/v1/models") \
  || die "failed to fetch Casper catalog"

# --- Fetch Baseten pricing --------------------------------------------------
log "Fetching Baseten pricing..."
BASETEN_MD=$(curl -sfL "$BASETEN_PRICING_URL") \
  || die "failed to fetch Baseten pricing page"

# --- Parse Baseten pricing table ---------------------------------------------
# Extract model name + input/cache/output prices from the markdown table.
# The table has repeated values (desktop + mobile), so we dedupe.
declare -A PRICE_INPUT PRICE_CACHE PRICE_OUTPUT

parse_pricing() {
  local line model input cache output
  local -a lines
  mapfile -t lines <<< "$BASETEN_MD"
  local i=0
  while [[ $i -lt ${#lines[@]} ]]; do
    line="${lines[$i]}"
    # Skip non-model lines
    if [[ ! "$line" =~ ^\[\!\[Image ]]; then
      ((i+=1))
      continue
    fi
    # Extract model name from markdown link
    model=$(echo "$line" | sed -n 's/.*) \([^]]*\)\](.*/\1/p')
    if [[ -z "$model" ]]; then
      ((i+=1))
      continue
    fi
    # Normalize model name to lowercase id-like key
    model_key=$(echo "$model" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
    # Prices are at fixed offsets from the model line:
    #   i+4: input, i+8: cache input, i+12: output (with [Try Model API] suffix)
    input="${lines[$((i+4))]:-}"
    cache="${lines[$((i+8))]:-}"
    output="${lines[$((i+12))]:-}"
    # Strip $ and whitespace; strip [Try Model API] suffix from output
    input=${input#\$}; input=${input//[[:space:]]/}
    cache=${cache#\$}; cache=${cache//[[:space:]]/}
    output=${output#\$}; output=${output%%\[*}; output=${output//[[:space:]]/}
    # Coerce "-" (no cache pricing) to 0
    [[ "$cache" == "-" ]] && cache="0"
    # Skip if already seen (mobile duplicate)
    # shellcheck disable=SC2034  # arrays read via nameref in get_price()
    if [[ -z "${PRICE_INPUT[$model_key]:-}" ]]; then
      PRICE_INPUT[$model_key]="$input"
      PRICE_CACHE[$model_key]="$cache"
      PRICE_OUTPUT[$model_key]="$output"
    fi
    # Skip past the mobile duplicate block (12 more lines)
    ((i += 14))
  done
}

parse_pricing

# --- Build Casper model list -------------------------------------------------
CASPER_MODELS=$(echo "$CASPER_JSON" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for m in data.get("data", []):
    print(json.dumps(m))
')

# --- Generate new models.yml --------------------------------------------------
TMP_MODELS=$(mktemp)
trap 'rm -f "$TMP_MODELS"' EXIT

cat > "$TMP_MODELS" <<'HEADER'
# Casper - Ditto's homegrown OpenAI-compatible AI router.
#
# Endpoint:  https://casper-api.ditto.live/v1
# Auth:      export CASPER_API_KEY=... (or add CASPER_API_KEY=... to ~/.env)
#            The apiKey value below is resolved as an env-var name first, literal second.
# Catalog:   GET /v1/models publishes context_length/max_model_len plus a per-model
#            `reasoning_param` naming the thinking wire. Values seen there:
#              - "reasoning_effort"                    -> provider baseline below
#              - "chat_template_args.enable_thinking"   -> per-model extraBody override
#              - ""                                    -> non-reasoning model
#            Re-check `GET /v1/models` after the router adds or retires a model.
# Pricing:   per-1M-token costs come from the Baseten pricing page, except models
#            Casper serves unmetered (FREE in the admin catalog at
#            https://casper.ditto.live/catalog), which free_model() zeroes out.
#            /v1/models does not expose the unmetered flag, so that list is
#            maintained by hand in the sync script.
# Access:    Invocation is entitled per key, and `GET /v1/models` lists the whole
#            catalog regardless of entitlement. Verified 2026-08-24: this key may
#            invoke `kimi-k3` and `auto`; `kimi-k2.6`, `glm-5.2`, and `dittoaicoder`
#            return 403 {"detail":"not authorized to invoke <id>"}. The named models
#            stay declared below so that widening `enabledModels` in config.yml is
#            the only change needed once access is granted.
# Known issue: kimi-k3 tool calls arrive as a single buffered SSE delta emitted
#            only after the full arguments are generated - the stream carries only
#            ":" heartbeat comments while a tool call is being built. The silent
#            window scales with argument size (~20 tok/s observed), and the router
#            enforces a 300s total upstream budget (raised from 240s on 2026-08-27);
#            crossing it aborts the stream. The kimi-k3 streamIdleTimeoutMs
#            override below is a local mitigation only; it does not fix the
#            underlying buffering.
providers:
  casper:
    baseUrl: https://casper-api.ditto.live/v1
    api: openai-completions
    apiKey: CASPER_API_KEY
    compat:
      # The router fronts self-hosted OSS engines, so OpenAI-only request
      # features are off and tool schemas go out non-strict.
      supportsStore: false
      supportsDeveloperRole: false
      supportsMultipleSystemMessages: false
      supportsUsageInStreaming: true
      maxTokensField: max_tokens
      supportsToolChoice: true
      supportsForcedToolChoice: true
      supportsStrictMode: false
      toolStrictMode: none
      # Majority wire: reasoning_effort. Models advertising a chat-template
      # switch override this per model.
      supportsReasoningEffort: true
      thinkingFormat: openai
      reasoningContentField: reasoning_content
      streamIdleTimeoutMs: 120000
    models:
HEADER

# Helper: map Casper id to Baseten pricing key
baseten_key_for() {
  local id="$1"
  case "$id" in
    auto)                    echo "" ;;
    kimi-k3)                 echo "kimi-k3" ;;
    kimi-k2.6)               echo "kimi-k2-6" ;;
    kimi-k2.7-code)          echo "kimi-k2-7-code" ;;
    glm-5.3)                 echo "glm-5-3" ;;
    glm-4.7)                 echo "glm-4-7" ;;
    deepseek-v4-pro)         echo "deepseek-v4-pro" ;;
    deepseek-v4-pro-0813)    echo "deepseek-v4-pro" ;;  # not yet in Baseten table; use Pro pricing
    deepseek-v4-flash-0731)  echo "deepseek-v4-flash-0731" ;;
    gpt-oss-120b)            echo "gpt-oss-120b" ;;
    inkling)                 echo "inkling" ;;
    inkling-small)           echo "inkling-small" ;;
    nemotron-3-ultra)        echo "nvidia-nemotron-3-ultra" ;;
    qwen3.8-27b)             echo "" ;;
    dittoaicoder)            echo "" ;;
    *)                       echo "" ;;
  esac
}

# Helper: models Casper serves unmetered (FREE in the admin catalog).
# The `unmetered` flag lives in Casper's admin DB and /v1/models deliberately
# does not expose it, so this list is maintained by hand against
# https://casper.ditto.live/catalog. Baseten pricing must NOT be applied to
# these: Casper bills nothing for them regardless of the upstream rate.
free_model() {
  case "$1" in
    glm-5.3|glm-5.3-flash) return 0 ;;
    *)                     return 1 ;;
  esac
}

# Helper: get price or default
get_price() {
  local key="$1" field="$2" default="$3"
  local -n arr="$field"
  if [[ -n "$key" && -n "${arr[$key]:-}" ]]; then
    echo "${arr[$key]}"
  else
    echo "$default"
  fi
}

# Write each model
while IFS= read -r model_json; do
  id=$(echo "$model_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')
  reasoning=$(echo "$model_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["reasoning"])')
  reasoning_param=$(echo "$model_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["reasoning_param"])')
  context_length=$(echo "$model_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["context_length"])')
  max_model_len=$(echo "$model_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["max_model_len"])')

  # Determine display name
  name=$(echo "$id" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)); print}')
  case "$id" in
    auto) name="Casper Auto Router" ;;
    deepseek-v4-pro-0813) name="DeepSeek V4 Pro (0813)" ;;
    deepseek-v4-flash-0731) name="DeepSeek V4 Flash (0731)" ;;
    gpt-oss-120b) name="GPT-OSS 120B" ;;
    qwen3.8-27b) name="Qwen3.8 27B" ;;
    dittoaicoder) name="Ditto AI Coder" ;;
  esac

  # Determine reasoning flag for OMP
  # Casper JSON returns Python-style True/False from the API
  if [[ "$reasoning" == "True" || "$reasoning" == "true" ]]; then
    omp_reasoning="true"
  else
    omp_reasoning="false"
  fi

  # Determine pricing
  if free_model "$id"; then
    price_input=0
    price_cache=0
    price_output=0
  else
    bkey=$(baseten_key_for "$id")
    price_input=$(get_price "$bkey" PRICE_INPUT "0")
    price_cache=$(get_price "$bkey" PRICE_CACHE "0")
    price_output=$(get_price "$bkey" PRICE_OUTPUT "0")
  fi

  # Determine compat overrides
  compat_lines=()
  thinking_switch=no
  if [[ "$reasoning_param" == "chat_template_args.enable_thinking" ]]; then
    thinking_switch=yes
    compat_lines+=("          supportsReasoningEffort: false")
  fi

  case "$id" in
    kimi-k3)
      compat_lines+=(
        "          # Casper buffers each tool call and emits it as a single delta, so the"
        "          # stream carries only SSE comments while arguments generate (~20 tok/s,"
        "          # measured 2026-08-24). Stay below the router's 300s total upstream"
        "          # budget so a timeout surfaces as an error, not a silent empty turn."
        "          streamIdleTimeoutMs: 210000"
      )
      ;;
    nemotron-3-ultra)
      compat_lines+=(
        "          # 550B class: first token can lag well past the provider floor."
        "          streamIdleTimeoutMs: 300000"
      )
      ;;
  esac

  if [[ "$thinking_switch" == yes ]]; then
    compat_lines+=(
      "          extraBody:"
      "            chat_template_args:"
      "              enable_thinking: false"
      "          whenThinking:"
      "            extraBody:"
      "              chat_template_args:"
      "                enable_thinking: true"
    )
  fi

  compat_extra=""
  if ((${#compat_lines[@]})); then
    compat_extra=$(printf '%s\n' "        compat:" "${compat_lines[@]}")
  fi

  # Write model entry
  cat >> "$TMP_MODELS" <<EOF
      - id: $id
        name: $name
        reasoning: $omp_reasoning
        input: [text]
        contextWindow: $context_length
        maxTokens: $max_model_len
        cost: { input: $price_input, output: $price_output, cacheRead: $price_cache, cacheWrite: 0 }
EOF
  if [[ -n "$compat_extra" ]]; then
    echo "$compat_extra" >> "$TMP_MODELS"
  fi
  echo >> "$TMP_MODELS"
done <<< "$CASPER_MODELS"

# --- Update config.yml if requested -------------------------------------------
if [[ "$UPDATE_ENABLED" == true ]]; then
  TMP_CONFIG=$(mktemp)
  trap 'rm -f "$TMP_CONFIG"' EXIT
  # Extract enabledModels block and replace with new list
  python3 - "$CONFIG_YML" "$CASPER_JSON" > "$TMP_CONFIG" <<'PY'
import json, sys, re

config_path = sys.argv[1]
casper_json = sys.argv[2]

with open(config_path) as f:
    content = f.read()

data = json.loads(casper_json)
models = [f"  - casper/{m['id']}" for m in data.get("data", [])]
new_block = "enabledModels:\n" + "\n".join(models)

# Replace existing enabledModels block
pattern = r"enabledModels:\n(?:  - .*\n?)*"
replacement = new_block + "\n"
new_content = re.sub(pattern, replacement, content, count=1)

print(new_content, end="")
PY
fi

# --- Write or dry-run ---------------------------------------------------------
if [[ "$DRY_RUN" == true ]]; then
  log "=== models.yml (dry run) ==="
  cat "$TMP_MODELS"
  if [[ "$UPDATE_ENABLED" == true ]]; then
    log "=== config.yml (dry run) ==="
    cat "$TMP_CONFIG"
  fi
  exit 0
fi

cp "$TMP_MODELS" "$MODELS_YML"
log "Updated $MODELS_YML"

if [[ "$UPDATE_ENABLED" == true ]]; then
  cp "$TMP_CONFIG" "$CONFIG_YML"
  log "Updated $CONFIG_YML"
fi

log "Done."
