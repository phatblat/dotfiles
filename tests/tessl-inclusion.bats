#!/usr/bin/env bats
# tessl-inclusion.bats — tessl stays out of harness memory files, and only its
# config is tracked. `tessl init` re-injects `@../.tessl/RULES.md` pointers into
# every harness memory file it can find; these tests fail when that happens.

load helpers/setup

INJECTED_FILES=(
  ".claude/CLAUDE.md"
  ".codex/AGENTS.md"
  ".gemini/AGENTS.md"
  ".copilot/copilot-instructions.md"
)

@test "tessl: harness memory files carry no tessl injection" {
  local found=()
  for f in "${INJECTED_FILES[@]}"; do
    [ -f "$HOME/$f" ] || continue
    if grep -qE '\.tessl/RULES\.md|tessl-managed' "$HOME/$f"; then
      found+=("$f")
    fi
  done
  if [ "${#found[@]}" -ne 0 ]; then
    echo "tessl re-injected into: ${found[*]}" >&2
    return 1
  fi
}

@test "tessl: credentials and runtime state are gitignored" {
  for f in \
    .tessl/api-credentials.json \
    .tessl/agent/auth.json \
    .tessl/remote-config.json \
    .tessl/llm-keys/deadbeef \
    .tessl/preferences.json \
    .tessl/anonymous-id
  do
    if ! git -C "$HOME" check-ignore -q "$f"; then
      echo "not ignored: $f" >&2
      return 1
    fi
  done
}

@test "tessl: config files stay tracked" {
  for f in .tessl/RULES.md .tessl/tessl.json; do
    if git -C "$HOME" check-ignore -q "$f"; then
      echo "wrongly ignored: $f" >&2
      return 1
    fi
  done
}
