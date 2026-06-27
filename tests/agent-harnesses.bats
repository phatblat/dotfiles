#!/usr/bin/env bats
# agent-harnesses.bats - Shared agent harness parity checks

load helpers/setup

SCRIPT="$HOME/scripts/agent-harnesses.py"

@test "agent-harnesses: inventories active commands, agents, skills, and graph capability" {
  run python3 "$SCRIPT" inventory --json

  [ "$status" -eq 0 ]
  command_count=$(printf '%s' "$output" | jq '.commands | length')
  agent_count=$(printf '%s' "$output" | jq '.agents | length')
  skill_count=$(printf '%s' "$output" | jq '.skills.count')
  has_graph=$(printf '%s' "$output" | jq -r '.capabilities | index("code-review-graph") != null')

  [ "$command_count" -eq 22 ]
  [ "$agent_count" -eq 6 ]
  [ "$skill_count" -gt 0 ]
  [ "$has_graph" = "true" ]
}

@test "agent-harnesses: generated artifacts are current" {
  run python3 "$SCRIPT" generate --check

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: cursor plugin artifacts exist" {
  [ -f "$HOME/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/rules/shared-harness.mdc" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/commands/git/commit.md" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/agents/triage-expert.md" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/hooks/hooks.json" ]
  [ -f "$HOME/.agents/harness/adapters/cursor/mcp.json" ]
}

@test "agent-harnesses: cursor plugin JSON files parse" {
  run jq . "$HOME/.agents/harness/adapters/cursor/.cursor-plugin/plugin.json"
  [ "$status" -eq 0 ]

  run jq . "$HOME/.agents/harness/adapters/cursor/hooks/hooks.json"
  [ "$status" -eq 0 ]

  run jq . "$HOME/.agents/harness/adapters/cursor/mcp.json"
  [ "$status" -eq 0 ]
}

@test "agent-harnesses: antigravity plugin artifacts exist and parse" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  adapter="$HOME/.agents/harness/adapters/antigravity"
  [ -f "$adapter/plugin.json" ]
  [ -f "$adapter/commands/git/commit.md" ]
  [ -f "$adapter/agents/triage-expert.md" ]
  [ -f "$adapter/hooks/hooks.json" ]
  [ -f "$adapter/scripts/harness-guard.py" ]
  [ -f "$adapter/mcp.json" ]

  command_count=$(find "$adapter/commands" -type f -name '*.md' | wc -l | tr -d ' ')
  agent_count=$(find "$adapter/agents" -type f -name '*.md' | wc -l | tr -d ' ')
  skill_count=$(find "$adapter/skills" -type f -name 'SKILL.md' | wc -l | tr -d ' ')
  inventory_skill_count=$(python3 "$SCRIPT" inventory --json | jq '.skills.count')

  [ "$command_count" -eq 22 ]
  [ "$agent_count" -eq 6 ]
  [ "$skill_count" -eq "$inventory_skill_count" ]

  jq . "$adapter/plugin.json" >/dev/null
  jq . "$adapter/hooks/hooks.json" >/dev/null
  jq . "$adapter/mcp.json" >/dev/null
}

@test "agent-harnesses: antigravity plugin validates when agy is installed" {
  command -v agy >/dev/null 2>&1 || skip "agy not installed"

  run agy plugin validate "$HOME/.agents/harness/adapters/antigravity"

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: safe shell commands pass every adapter guard" {
  for harness in claude codex opencode pi antigravity cursor; do
    run python3 "$SCRIPT" guard --harness "$harness" --tool bash --command "git status --short"
    [ "$status" -eq 0 ]
    decision=$(printf '%s' "$output" | jq -r '.decision')
    [ "$decision" = "allow" ]
  done
}

@test "agent-harnesses: dangerous shell commands are denied consistently" {
  for harness in claude codex opencode pi antigravity cursor; do
    run python3 "$SCRIPT" guard --harness "$harness" --tool bash --command "rm -rf /"
    [ "$status" -eq 2 ]
    decision=$(printf '%s' "$output" | jq -r '.decision')
    reason=$(printf '%s' "$output" | jq -r '.reason')
    [ "$decision" = "deny" ]
    [[ "$reason" == *"Dangerous command"* ]]
  done
}

@test "agent-harnesses: protected writes are denied consistently" {
  for harness in claude codex opencode pi antigravity cursor; do
    run python3 "$SCRIPT" guard --harness "$harness" --tool write --path "$HOME/.ssh/id_ed25519" --content "not a key"
    [ "$status" -eq 2 ]
    decision=$(printf '%s' "$output" | jq -r '.decision')
    reason=$(printf '%s' "$output" | jq -r '.reason')
    [ "$decision" = "deny" ]
    [[ "$reason" == *"protected file"* ]]
  done
}

@test "agent-harnesses: secret-like content is denied consistently" {
  for harness in claude codex opencode pi antigravity cursor; do
    run python3 "$SCRIPT" guard --harness "$harness" --tool write --path "$HOME/tmp/example.txt" --content "token = sk-example12345678901234567890"
    [ "$status" -eq 2 ]
    decision=$(printf '%s' "$output" | jq -r '.decision')
    reason=$(printf '%s' "$output" | jq -r '.reason')
    [ "$decision" = "deny" ]
    [[ "$reason" == *"secret-like content"* ]]
  done
}

@test "agent-harnesses: generated guard wrappers forward cwd" {
  repo="$(mktemp -d)"
  git -C "$repo" init -q -b main
  empty_tree="$(git -C "$repo" mktree </dev/null)"
  parent=""
  for index in $(seq 1 100); do
    if [ -n "$parent" ]; then
      commit="$(
        GIT_AUTHOR_NAME="Harness Test" \
          GIT_AUTHOR_EMAIL="harness@example.invalid" \
          GIT_COMMITTER_NAME="Harness Test" \
          GIT_COMMITTER_EMAIL="harness@example.invalid" \
          git -C "$repo" commit-tree "$empty_tree" -p "$parent" -m "commit $index"
      )"
    else
      commit="$(
        GIT_AUTHOR_NAME="Harness Test" \
          GIT_AUTHOR_EMAIL="harness@example.invalid" \
          GIT_COMMITTER_NAME="Harness Test" \
          GIT_COMMITTER_EMAIL="harness@example.invalid" \
          git -C "$repo" commit-tree "$empty_tree" -m "commit $index"
      )"
    fi
    parent="$commit"
  done
  git -C "$repo" update-ref refs/heads/main "$parent"
  git -C "$repo" checkout -q main

  payload="$(jq -nc --arg cwd "$repo" '{tool: "bash", command: "git commit -m test", cwd: $cwd}')"

  for wrapper in \
    "$HOME/.agents/harness/adapters/antigravity/scripts/harness-guard.py" \
    "$HOME/.agents/harness/adapters/cursor/scripts/harness-guard.py"; do
    run python3 "$wrapper" <<<"$payload"
    [ "$status" -eq 0 ]
    decision="$(printf '%s' "$output" | jq -r '.decision')"
    reason="$(printf '%s' "$output" | jq -r '.reason')"
    [ "$decision" = "warn" ]
    [[ "$reason" == *"protected 'main' branch"* ]]
  done
}
