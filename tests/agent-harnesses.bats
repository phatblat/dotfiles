#!/usr/bin/env bats
# agent-harnesses.bats - Shared agent harness parity checks

load helpers/setup

SCRIPT="$HOME/scripts/agent-harnesses.py"

@test "agent-harnesses: plugin normalizers pass unit tests" {
  run python3 "$HOME/tests/test_agent_plugins.py"

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: inventories active commands, agents, skills, and graph capability" {
  run python3 "$SCRIPT" inventory --json

  [ "$status" -eq 0 ]
  command_count=$(printf '%s' "$output" | jq '.commands | length')
  agent_count=$(printf '%s' "$output" | jq '.agents | length')
  skill_count=$(printf '%s' "$output" | jq '.skills.count')
  has_graph=$(printf '%s' "$output" | jq -r '.capabilities | index("code-review-graph") != null')
  claude_plugins=$(printf '%s' "$output" | jq '.plugins.claude | type')
  codex_plugins=$(printf '%s' "$output" | jq '.plugins.codex | type')

  [ "$command_count" -eq 24 ]
  [ "$agent_count" -eq 6 ]
  [ "$skill_count" -gt 0 ]
  [ "$has_graph" = "true" ]
  [ "$claude_plugins" = '"array"' ]
  [ "$codex_plugins" = '"array"' ]
}

@test "agent-harnesses: generated artifacts are current" {
  run python3 "$SCRIPT" generate --check

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: generation removes obsolete skill wrappers" {
  stale_skill="obsolete-generated-skill"
  antigravity_dir="$HOME/.agents/harness/adapters/antigravity/skills/$stale_skill"
  cursor_dir="$HOME/.agents/harness/adapters/cursor/skills/$stale_skill"
  modified_skill="modified-generated-skill"
  modified_dir="$HOME/.agents/harness/adapters/antigravity/skills/$modified_skill"
  symlink_skill="symlink-generated-skill"
  symlink_dir="$HOME/.agents/harness/adapters/antigravity/skills/$symlink_skill"
  symlink_target="$BATS_TEST_TMPDIR/$symlink_skill"

  mkdir -p "$antigravity_dir" "$cursor_dir" "$modified_dir" "$symlink_target"
  sed "s|boris|$stale_skill|g" \
    "$HOME/.agents/harness/adapters/antigravity/skills/boris/SKILL.md" \
    >"$antigravity_dir/SKILL.md"
  sed "s|boris|$stale_skill|g" \
    "$HOME/.agents/harness/adapters/cursor/skills/boris/SKILL.md" \
    >"$cursor_dir/SKILL.md"
  printf '%s\n' "preserve this sidecar" >"$cursor_dir/notes.md"
  sed "s|boris|$modified_skill|g" \
    "$HOME/.agents/harness/adapters/antigravity/skills/boris/SKILL.md" \
    >"$modified_dir/SKILL.md"
  printf '%s\n' "<!-- manually modified -->" >>"$modified_dir/SKILL.md"
  sed "s|boris|$symlink_skill|g" \
    "$HOME/.agents/harness/adapters/antigravity/skills/boris/SKILL.md" \
    >"$symlink_target/SKILL.md"
  ln -s "$symlink_target" "$symlink_dir"

  antigravity_hash="$(shasum -a 256 "$antigravity_dir/SKILL.md")"
  cursor_hash="$(shasum -a 256 "$cursor_dir/SKILL.md")"

  run python3 "$SCRIPT" generate --check
  check_status="$status"
  check_output="$output"
  antigravity_hash_after_check="$(shasum -a 256 "$antigravity_dir/SKILL.md")"
  cursor_hash_after_check="$(shasum -a 256 "$cursor_dir/SKILL.md")"

  run python3 "$SCRIPT" generate
  generate_status="$status"
  antigravity_exists="$([ -e "$antigravity_dir" ] && echo true || echo false)"
  cursor_skill_exists="$([ -e "$cursor_dir/SKILL.md" ] && echo true || echo false)"
  cursor_sidecar_exists="$([ -e "$cursor_dir/notes.md" ] && echo true || echo false)"
  modified_exists="$([ -e "$modified_dir/SKILL.md" ] && echo true || echo false)"
  symlink_exists="$([ -L "$symlink_dir" ] && echo true || echo false)"
  symlink_target_exists="$([ -e "$symlink_target/SKILL.md" ] && echo true || echo false)"

  run python3 "$SCRIPT" generate
  second_generate_status="$status"
  run python3 "$SCRIPT" generate --check
  idempotent_check_status="$status"

  rm -f \
    "$cursor_dir/SKILL.md" \
    "$cursor_dir/notes.md" \
    "$modified_dir/SKILL.md" \
    "$symlink_dir"
  rmdir "$cursor_dir" "$modified_dir" 2>/dev/null || true

  [ "$check_status" -eq 1 ]
  [[ "$check_output" == *"obsolete: ~/.agents/harness/adapters/antigravity/skills/$stale_skill/SKILL.md"* ]]
  [[ "$check_output" == *"obsolete: ~/.agents/harness/adapters/cursor/skills/$stale_skill/SKILL.md"* ]]
  [[ "$check_output" != *"$modified_skill"* ]]
  [[ "$check_output" != *"$symlink_skill"* ]]
  [ "$antigravity_hash_after_check" = "$antigravity_hash" ]
  [ "$cursor_hash_after_check" = "$cursor_hash" ]
  [ "$generate_status" -eq 0 ]
  [ "$antigravity_exists" = false ]
  [ "$cursor_skill_exists" = false ]
  [ "$cursor_sidecar_exists" = true ]
  [ "$modified_exists" = true ]
  [ "$symlink_exists" = true ]
  [ "$symlink_target_exists" = true ]
  [ "$second_generate_status" -eq 0 ]
  [ "$idempotent_check_status" -eq 0 ]
}

@test "agent-harnesses: generated manifest contains native plugin matrix" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  jq -e '.plugins.claude and .plugins.codex' \
    "$HOME/docs/agent-harnesses.json" >/dev/null
  grep -Fq '## Native Plugins' "$HOME/docs/agent-harnesses.md"
  grep -Fq '| Plugin | Claude | Codex |' "$HOME/docs/agent-harnesses.md"
  grep -Fq '| pup@datadog-pup | enabled | enabled |' \
    "$HOME/docs/agent-harnesses.md"
}

@test "agent-harnesses: audit reports observed plugins and drift" {
  run python3 "$SCRIPT" audit --json

  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq '.plugins.observed | type')" = '"object"' ]
  [ "$(printf '%s' "$output" | jq '.plugins.drift | type')" = '"array"' ]
}

@test "agent-harnesses: pr-daily layers new branches on the current daily branch" {
  for workflow in \
    "$HOME/.claude/commands/pr/daily.md" \
    "$HOME/.agents/skills/pr-daily/SKILL.md"; do
    grep -Fq 'source_branch=${current_branch}' "$workflow"
    grep -Fq 'git checkout -b "${today}" "${source_branch}"' "$workflow"
    grep -Fq 'comparison_branch=${default_branch}' "$workflow"
    grep -Fq 'if [ "${source_branch}" != "${today}" ]; then' "$workflow"
    grep -Fq 'comparison_branch=${source_branch}' "$workflow"
    grep -Fq 'git rev-list --count "${comparison_branch}..${today}"' "$workflow"
    grep -Fq 'git commit --allow-empty -m "chore: start ${today} ${today_date}"' "$workflow"
    grep -Fq 'gh pr create --draft --base "${default_branch}"' "$workflow"
    ! grep -Eq 'git checkout "?\$\{default_branch\}"?' "$workflow"

    default_comparison_line="$(grep -nF 'comparison_branch=${default_branch}' "$workflow" | head -1 | cut -d: -f1)"
    source_guard_line="$(grep -nF 'if [ "${source_branch}" != "${today}" ]; then' "$workflow" | head -1 | cut -d: -f1)"
    source_comparison_line="$(grep -nF 'comparison_branch=${source_branch}' "$workflow" | head -1 | cut -d: -f1)"
    rev_list_line="$(grep -nF 'git rev-list --count "${comparison_branch}..${today}"' "$workflow" | head -1 | cut -d: -f1)"
    marker_commit_line="$(grep -nF 'git commit --allow-empty -m "chore: start ${today} ${today_date}"' "$workflow" | head -1 | cut -d: -f1)"
    [ "$default_comparison_line" -lt "$source_guard_line" ]
    [ "$source_guard_line" -lt "$source_comparison_line" ]
    [ "$source_comparison_line" -lt "$rev_list_line" ]
    [ "$rev_list_line" -lt "$marker_commit_line" ]

    grep -Eiq 'skip(ping)? .*source.*\$\{source_branch\}|skip(ping)?.*\$\{source_branch\}.*source' "$workflow"
    grep -Eiq 'any other branch.*ask whether to use.*or abort' "$workflow"
    grep -Eiq 'diverg(ed|ence).*ask how to proceed' "$workflow"
    grep -Eiq 'status[^[:alnum:]]*0.*(fetch|fast-forward|sync)' "$workflow"
    grep -Eiq 'status[^[:alnum:]]*2.*(absent|missing|not found|does not exist|local)' "$workflow"
    grep -Eiq '((any|all) other|other non-?zero).*status.*(stop|abort|report)|status.*(other|otherwise).*(stop|abort|report)' "$workflow"
    grep -Fq 'git merge --ff-only "${remote}/${source_branch}"' "$workflow"
  done
}

@test "agent-harnesses: procedural Codex skills require explicit invocation" {
  procedural_skills=(
    branch-finish
    dupe
    git-cleanup
    git-commit
    git-push
    git-rebase
    git-split
    git-status
    git-worktrees
    gh-stack
    gha-checks
    gha-log-reader
    linear-plan
    optimize
    pr-create
    pr-daily
    pr-merge
    pr-open-for-review
    pr-post-findings
    pr-resolve-feedback
    pr-update-desc
    resolve-feedback
    retro
    session-save
    work-eod
    work-runners
    work-start
    work-track
  )

  for skill in "${procedural_skills[@]}"; do
    sidecar="$HOME/.agents/skills/$skill/agents/openai.yaml"
    [ -f "$sidecar" ]
    grep -Fx "policy:" "$sidecar"
    grep -Fx "  allow_implicit_invocation: false" "$sidecar"
  done
}

@test "agent-harnesses: Claude and Codex know Obsidian daily-note location" {
  for instructions in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    [ -f "$instructions" ]
    grep -F "Obsidian" "$instructions"
    grep -F "~/2ndBrain/daily-notes/<YYYY>/<YYYY-MM-DD dddd>.md" "$instructions"
    grep -F "Only use Notion when explicitly requested" "$instructions"
  done
}

@test "agent-harnesses: pr-post-findings preserves the Obsidian worklog contract" {
  claude_workflow="$HOME/.claude/commands/pr/post-findings.md"
  codex_workflow="$HOME/.agents/skills/pr-post-findings/SKILL.md"

  for workflow in "$claude_workflow" "$codex_workflow"; do
    grep -Fq 'so the worklog captures which PRs you reviewed and every comment you left' "$workflow"
    grep -Fq 'note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"' "$workflow"
    grep -Fq '<!-- pr:post-findings appends reviewed PRs here -->' "$workflow"
    grep -Fq 'PR already listed' "$workflow"
    grep -Fq 'PR not listed' "$workflow"
  done

  grep -Fq 'Make the daily-note update before reporting success.' "$codex_workflow"
  grep -Fq 'Verify that every captured `comment_url` appears in the updated entry.' "$codex_workflow"
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

  [ "$command_count" -eq 24 ]
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

@test "agent-harnesses: privilege escalation after shell separators is denied consistently" {
  privileged_commands=(
    "echo x | sudo tee /etc/hosts"
    "printf x | su - root"
    $'echo ok\nsudo whoami'
  )

  for harness in claude codex opencode pi antigravity cursor; do
    for privileged_command in "${privileged_commands[@]}"; do
      run python3 "$SCRIPT" guard --harness "$harness" --tool bash --command "$privileged_command"
      [ "$status" -eq 2 ]
      decision=$(printf '%s' "$output" | jq -r '.decision')
      reason=$(printf '%s' "$output" | jq -r '.reason')
      [ "$decision" = "deny" ]
      [[ "$reason" == *"Privilege escalation"* ]]
    done
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

@test "agent-harnesses: documented protected paths are denied consistently" {
  protected_paths=(
    "$HOME/.gemini/google_accounts.json"
    "$HOME/.gemini/oauth_creds.json"
    "$HOME/.gemini/antigravity-cli/installation_id"
    "$HOME/.gemini/antigravity-cli/conversations/session.json"
    "$HOME/.cursor/ai-tracking/state.json"
  )

  for harness in claude codex opencode pi antigravity cursor; do
    for protected_path in "${protected_paths[@]}"; do
      run python3 "$SCRIPT" guard --harness "$harness" --tool write --path "$protected_path" --content "{}"
      [ "$status" -eq 2 ]
      decision=$(printf '%s' "$output" | jq -r '.decision')
      reason=$(printf '%s' "$output" | jq -r '.reason')
      [ "$decision" = "deny" ]
      [[ "$reason" == *"protected file"* ]]
    done
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
