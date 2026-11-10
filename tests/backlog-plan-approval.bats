#!/usr/bin/env bats
# Task completion test for harness-native plan approval surfaces

@test "backlog skill splits plan approval by harness branch" {
  skill_body="$(cat "$BATS_TEST_DIRNAME/../.agents/skills/backlog-batch-delivery/SKILL.md")"

  for token in "ExitPlanMode" "xd://propose"; do
    echo "$skill_body" | grep -Fq "$token" || {
      echo "missing $token"
      exit 1
    }
  done

  claude_seg="$(printf '%s\n' "$skill_body" | sed -n '/\*\*Claude Code\*\*/p')"
  [[ "$claude_seg" == *"ExitPlanMode"* ]]
  [[ "$claude_seg" == *"never emit"* ]]
  [[ "$claude_seg" == *"xd://propose"* ]]
}

@test "retro command stops treating TaskOutput as the standard wait API" {
  retro_body="$(cat "$BATS_TEST_DIRNAME/../.agents/harness/commands/retro.md")"
  [[ "$retro_body" == *"TaskStop"* ]]
  [[ "$retro_body" != *"TaskOutput"* ]]
}

@test "plan-driven skills prefer native task tools with TodoWrite fallback" {
  for skill in executing-plans subagent-driven-development; do
    body="$(cat "$BATS_TEST_DIRNAME/../.agents/skills/$skill/SKILL.md")"
    [[ "$body" == *"TaskCreate"* ]]
    [[ "$body" == *"TodoWrite"* ]]
    ! printf '%s\n' "$body" | grep -Fq "TodoWrite with all tasks" || true
    ! printf '%s\n' "$body" | grep -Fq "Mark task complete in TodoWrite" || true
  done
}

@test "native capability guide forbids OMP device emulation in Claude" {
  guide="$(cat "$BATS_TEST_DIRNAME/../.agents/harness/native-capabilities.md")"
  [[ "$guide" == *"Never emit OMP \`xd://\` URIs"* ]]
  [[ "$guide" == *"| `propose`"* ]]
  [[ "$guide" == *"ExitPlanMode"* ]]
  [[ "$guide" == *"subagent-output-schema-contract"* ]]
}
