#!/usr/bin/env bats
# agent-harnesses.bats - Shared agent harness parity checks

load helpers/setup

SCRIPT="$HOME/scripts/agent-harnesses.py"

@test "agent-harnesses: plugin normalizers pass unit tests" {
  run python3 "$HOME/tests/test_agent_plugins.py"

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: inventories active commands, agents, and skills without a graph capability" {
  run python3 "$SCRIPT" inventory --json

  [ "$status" -eq 0 ]
  command_count=$(printf '%s' "$output" | jq '.commands | length')
  agent_count=$(printf '%s' "$output" | jq '.agents | length')
  skill_count=$(printf '%s' "$output" | jq '.skills.count')
  has_graph=$(printf '%s' "$output" | jq -r '.capabilities | index("code-review-graph") != null')
  claude_plugins=$(printf '%s' "$output" | jq '.plugins.claude | type')
  codex_plugins=$(printf '%s' "$output" | jq '.plugins.codex | type')

  [ "$command_count" -eq 26 ]
  [ "$agent_count" -eq 6 ]
  [ "$skill_count" -gt 0 ]
  [ "$has_graph" = "false" ]
  [ "$claude_plugins" = '"array"' ]
  [ "$codex_plugins" = '"array"' ]
}

@test "agent harnesses do not inject session-start context" {
  ! jq -e '[.hooks.SessionStart[]?.hooks[]?.command | test("session-start\\.sh")] | any' \
    "$HOME/.codex/hooks.json"
  ! jq -e '[.hooks.SessionStart[]?.hooks[]?.command | test("session-start\\.sh")] | any' \
    "$HOME/.claude/settings.json"
}

@test "agent-harnesses: Linear CLI workflows preserve macOS keychain access" {
  linear_workflows=(
    "$HOME/.agents/skills/linear-plan/SKILL.md"
    "$HOME/.agents/skills/work-end-day/SKILL.md"
    "$HOME/.agents/skills/work-start/SKILL.md"
    "$HOME/.agents/skills/work-track/SKILL.md"
    "$HOME/.claude/commands/linear/plan.md"
    "$HOME/.claude/commands/linear/progress.md"
    "$HOME/.claude/commands/work/end-day.md"
    "$HOME/.claude/commands/work/start-day.md"
    "$HOME/.claude/commands/work/track-item.md"
  )

  for workflow in "${linear_workflows[@]}"; do
    grep -Fq 'run every `linear ...` command outside the sandbox' "$workflow"
    grep -Fq 'prefix_rule: ["linear"]' "$workflow"
    grep -Fq 'No keyring entry' "$workflow"
    grep -Fq 'No API key configured' "$workflow"
    grep -Fq 'before asking the user to authenticate' "$workflow"
    grep -Fq 'Never print, log, or expose' "$workflow"
  done
}

@test "agent-harnesses: generated artifacts are current" {
  run python3 "$SCRIPT" generate --check

  [ "$status" -eq 0 ]
}

@test "agent-harnesses: commit guidance favors targeted checks" {
  commit_workflows=(
    "$HOME/.claude/commands/git/commit.md"
    "$HOME/.agents/harness/commands/git/commit.md"
    "$HOME/.agents/skills/git-commit/SKILL.md"
  )

  for workflow in "${commit_workflows[@]}"; do
    grep -Fq "Run the project's lint command and only tests directly relevant to changed files" "$workflow"
    grep -Fq "Run a repository-wide test suite only when the user explicitly requests it" "$workflow"
    ! grep -Fq "Run tests and lint commands to ensure code quality" "$workflow"
  done

  grep -Fq 'Run `just lint` and only the Bats files relevant to the changed behavior' "$HOME/AGENTS.md"
  ! grep -Fq 'Run locally with `just test`' "$HOME/AGENTS.md"
  ! grep -Fq 'just lint && just test' "$HOME/AGENTS.md"
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
  grep -Fq '| pup@datadog-pup | disabled | enabled |' \
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
    handoff
    gha-log-reader
    justfile
    linear-plan
    optimize-harness
    pr-create
    pr-daily
    pr-merge
    pr-open-for-review
    pr-post-review-findings
    pr-resolve-feedback
    pr-update-desc
    resolve-feedback
    retro
    session-save
    work-end-day
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

@test "handoff skill records a complete, manual-only continuation brief" {
  skill="$HOME/.agents/skills/handoff/SKILL.md"
  sidecar="$HOME/.agents/skills/handoff/agents/openai.yaml"

  grep -Fq 'Do **not** ask the user clarifying questions.' "$skill"
  grep -Fq 'docs/handoffs/YYYY-MM-DD-<topic>.md' "$skill"
  grep -Fq '## Open Questions' "$skill"
  grep -Fq '## Confidence' "$skill"
  grep -Fq '## Estimate' "$skill"
  grep -Fq '## Suggested Agent Structure' "$skill"
  grep -Fq 'git add -- "docs/handoffs/YYYY-MM-DD-<topic>.md"' "$skill"
  grep -Fx '  allow_implicit_invocation: false' "$sidecar"
}

@test "handoff skill has generated native adapters" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  for skill in \
    "$HOME/.claude/skills/handoff/SKILL.md" \
    "$HOME/.codex/skills/handoff/SKILL.md" \
    "$HOME/.config/opencode/skills/handoff/SKILL.md"; do
    [ -f "$skill" ]
    grep -Fq 'Load and follow the shared skill at `~/.agents/skills/handoff/SKILL.md`.' "$skill"
  done

  grep -Fx 'disable-model-invocation: true' "$HOME/.claude/skills/handoff/SKILL.md"
  grep -Fx '  allow_implicit_invocation: false' \
    "$HOME/.codex/skills/handoff/agents/openai.yaml"
}

@test "aven skill has generated ability adapters" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  canonical="$HOME/.agents/skills/aven/SKILL.md"
  [ -f "$canonical" ]
  grep -Fq "name: aven" "$canonical"
  grep -Fq "Use aven to find tasks" "$canonical"

  for skill in \
    "$HOME/.claude/skills/aven/SKILL.md" \
    "$HOME/.codex/skills/aven/SKILL.md" \
    "$HOME/.config/opencode/skills/aven/SKILL.md"; do
    [ -f "$skill" ]
    grep -Fq 'Load and follow the shared skill at `~/.agents/skills/aven/SKILL.md`.' "$skill"
  done

  ! grep -Fq "disable-model-invocation: true" \
    "$HOME/.claude/skills/aven/SKILL.md"
  [ ! -e "$HOME/.codex/skills/aven/agents/openai.yaml" ]

  for skill in \
    "$HOME/.agents/harness/adapters/antigravity/skills/aven/SKILL.md" \
    "$HOME/.agents/harness/adapters/cursor/skills/aven/SKILL.md"; do
    [ -f "$skill" ]
    grep -Fq 'Load and follow the shared skill at `~/.agents/skills/aven/SKILL.md`.' "$skill"
  done
}

@test "aven native adapters are tracked" {
  run git -C "$HOME" ls-files --error-unmatch .codex/skills/aven/SKILL.md
  [ "$status" -eq 0 ]

  run git -C "$HOME" ls-files --error-unmatch .config/opencode/skills/aven/SKILL.md
  [ "$status" -eq 0 ]
}

@test "grill-me front door and grilling primitive are wired across harnesses" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  primitive="$HOME/.agents/skills/grilling/SKILL.md"
  front_door="$HOME/.agents/skills/grill-me/SKILL.md"

  grep -Fq 'name: grilling' "$primitive"
  grep -Fq 'Work the tree in **rounds**.' "$primitive"
  grep -Fq '➡️ <your recommended answer>' "$primitive"
  ! grep -Fq 'disable-model-invocation: true' "$primitive"

  grep -Fx 'disable-model-invocation: true' "$front_door"
  grep -Fq '~/.agents/skills/grilling/SKILL.md' "$front_door"
  grep -Fx '  allow_implicit_invocation: false' \
    "$HOME/.agents/skills/grill-me/agents/openai.yaml"

  for skill in grill-me grilling; do
    for pointer in \
      "$HOME/.claude/skills/$skill/SKILL.md" \
      "$HOME/.codex/skills/$skill/SKILL.md" \
      "$HOME/.config/opencode/skills/$skill/SKILL.md" \
      "$HOME/.agents/harness/adapters/antigravity/skills/$skill/SKILL.md" \
      "$HOME/.agents/harness/adapters/cursor/skills/$skill/SKILL.md"; do
      [ -f "$pointer" ]
      grep -Fq "Load and follow the shared skill at \`~/.agents/skills/$skill/SKILL.md\`." "$pointer"
      run git -C "$HOME" ls-files --error-unmatch "$pointer"
      [ "$status" -eq 0 ]
    done
  done

  grep -Fx 'disable-model-invocation: true' "$HOME/.claude/skills/grill-me/SKILL.md"
  grep -Fx '  allow_implicit_invocation: false' \
    "$HOME/.codex/skills/grill-me/agents/openai.yaml"
  ! grep -Fq 'disable-model-invocation: true' "$HOME/.claude/skills/grilling/SKILL.md"
  [ ! -e "$HOME/.codex/skills/grilling/agents/openai.yaml" ]
}

@test "agent-harnesses: Claude and Codex know Obsidian daily-note location" {
  for instructions in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"; do
    [ -f "$instructions" ]
    grep -F "Obsidian" "$instructions"
    grep -F "~/2ndBrain/daily-notes/<YYYY>/<YYYY-MM-DD dddd>.md" "$instructions"
    grep -F "Only use Notion when explicitly requested" "$instructions"
  done
}

@test "agent-harnesses: pr-post-review-findings preserves the Obsidian worklog contract" {
  claude_workflow="$HOME/.claude/commands/pr/post-review-findings.md"
  codex_workflow="$HOME/.agents/skills/pr-post-review-findings/SKILL.md"

  for workflow in "$claude_workflow" "$codex_workflow"; do
    grep -Fq 'so the worklog captures which PRs you reviewed and every comment you left' "$workflow"
    grep -Fq 'note_path="$HOME/2ndBrain/daily-notes/${today_year}/${today_date} ${today_day}.md"' "$workflow"
    grep -Fq '<!-- pr:post-review-findings appends reviewed PRs here -->' "$workflow"
    grep -Fq 'PR already listed' "$workflow"
    grep -Fq 'PR not listed' "$workflow"
  done

  grep -Fq 'Make the daily-note update before reporting success.' "$codex_workflow"
  grep -Fq 'Verify that every captured `comment_url` appears in the updated entry.' "$codex_workflow"
}

@test "agent-harnesses: work:start-day seeds the same Reviews anchor pr-post-review-findings expects" {
  start_day="$HOME/.claude/commands/work/start-day.md"
  post_review="$HOME/.claude/commands/pr/post-review-findings.md"

  anchor='<!-- pr:post-review-findings appends reviewed PRs here -->'
  grep -Fq "$anchor" "$start_day"
  grep -Fq "$anchor" "$post_review"

  # Guard against stale pre-rename anchor/command-name text lingering in start-day.md.
  ! grep -F 'pr:post-findings' "$start_day"
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

@test "agent-harnesses: grok artifacts exist and parse" {
  run python3 "$SCRIPT" generate --check
  [ "$status" -eq 0 ]

  [ -f "$HOME/.grok/config.toml" ]
  [ -f "$HOME/.grok/rules/shared-harness.md" ]
  [ -f "$HOME/.grok/scripts/harness-guard.py" ]
  [ -f "$HOME/.grok/agents/triage-expert.md" ]

  run jq . "$HOME/.grok/hooks/harness-guard.json"
  [ "$status" -eq 0 ]

  grep -Fq 'hooks = false' "$HOME/.grok/config.toml"
  grep -Fq 'Shared Harness Instructions' "$HOME/.grok/rules/shared-harness.md"
  grep -Fq 'Context Compaction Preservation' "$HOME/.grok/rules/shared-harness.md"
  grep -Fq 'Co-Authored-By: grokkybara[bot] <304785771+grokkybara[bot]@users.noreply.github.com>' "$HOME/.grok/rules/shared-harness.md"
}

@test "agent-harnesses: grok guard wrapper maps camelCase payloads" {
  wrapper="$HOME/.grok/scripts/harness-guard.py"

  deny_payload="$(jq -nc '{hookEventName: "pre_tool_use", cwd: $ENV.HOME,
    toolName: "run_terminal_command", toolInput: {command: "sudo -n true"}}')"
  run python3 "$wrapper" <<<"$deny_payload"
  [ "$status" -eq 2 ]
  [ "$(printf '%s' "$output" | jq -r '.decision')" = "deny" ]

  write_payload="$(jq -nc --arg path "$HOME/.ssh/id_ed25519" '{hookEventName: "pre_tool_use",
    cwd: $ENV.HOME, toolName: "search_replace",
    toolInput: {file_path: $path, new_string: "x"}}')"
  run python3 "$wrapper" <<<"$write_payload"
  [ "$status" -eq 2 ]
  [ "$(printf '%s' "$output" | jq -r '.decision')" = "deny" ]

  allow_payload="$(jq -nc '{hookEventName: "pre_tool_use", cwd: $ENV.HOME,
    toolName: "run_terminal_command", toolInput: {command: "git status --short"}}')"
  run python3 "$wrapper" <<<"$allow_payload"
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.decision')" = "allow" ]
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

  [ "$command_count" -eq 26 ]
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
  for harness in claude codex opencode pi omp antigravity cursor grok; do
    run python3 "$SCRIPT" guard --harness "$harness" --tool bash --command "git status --short"
    [ "$status" -eq 0 ]
    decision=$(printf '%s' "$output" | jq -r '.decision')
    [ "$decision" = "allow" ]
  done
}

@test "agent-harnesses: dangerous shell commands are denied consistently" {
  for harness in claude codex opencode pi omp antigravity cursor grok; do
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

  for harness in claude codex opencode pi omp antigravity cursor grok; do
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
  for harness in claude codex opencode pi omp antigravity cursor grok; do
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
    "$HOME/.grok/auth.json"
    "$HOME/.grok/mcp_credentials.json"
  )

  for harness in claude codex opencode pi omp antigravity cursor grok; do
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
  for harness in claude codex opencode pi omp antigravity cursor grok; do
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

@test "agent-harnesses: generated-paths manifest resolves and covers header-less artifacts" {
  manifest="$HOME/.agents/harness/generated-paths.json"
  [ -f "$manifest" ]

  # Every key must name a file that exists, or the guard denies writes to paths
  # that are gone while missing the ones that are not.
  run python3 -c 'import json, sys
from pathlib import Path
home = Path(sys.argv[2])
manifest = json.loads(Path(sys.argv[1]).read_text())
missing = [k for k in manifest if not (home / k[2:]).exists()]
if missing:
    print("missing:", missing[:5])
    raise SystemExit(1)
' "$manifest" "$HOME"
  [ "$status" -eq 0 ]

  # These artifacts are JSON and cannot carry MANAGED_HEADER, so the manifest is
  # the only way the guard can recognize them as generated.
  run jq -e '."~/.pi/agent/agents.json"' "$manifest"
  [ "$status" -eq 0 ]
  run jq -e '."~/.agents/harness/generated-paths.json"' "$manifest"
  [ "$status" -eq 0 ]
}

@test "agent-harnesses: guard denies writes to generated artifacts and names the source" {
  run python3 "$SCRIPT" guard --harness omp --tool write \
    --path "$HOME/.agents/harness/commands/git/commit.md" --content "x"

  [ "$status" -eq 2 ]
  [ "$(printf '%s' "$output" | jq -r '.decision')" = "deny" ]
  [[ "$(printf '%s' "$output" | jq -r '.reason')" == *".claude/commands/git/commit.md"* ]]
}

@test "agent-harnesses: guard allows writes to hand-written sources" {
  run python3 "$SCRIPT" guard --harness omp --tool write \
    --path "$HOME/.claude/commands/git/commit.md" --content "x"

  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.decision')" = "allow" ]
}

@test "agent-harnesses: guard denies writes to the control plane" {
  for target in \
    ".agents/harness/hooks/safety.py" \
    "scripts/agent-harnesses.py" \
    ".agents/harness/self-improve-policy.json" \
    ".agents/harness/generated-paths.json"; do
    run python3 "$SCRIPT" guard --harness omp --tool write \
      --path "$HOME/$target" --content "x"

    [ "$status" -eq 2 ]
    [ "$(printf '%s' "$output" | jq -r '.decision')" = "deny" ]
  done
}

# The path rules were write-tool-only, so `echo x >> safety.py` reached the
# guard's own source and one redirect could blank the generated-path manifest,
# taking every generated artifact unprotected with it.
@test "agent-harnesses: guard denies shell writes to protected and control-plane paths" {
  for command in \
    "echo x >> $HOME/.agents/harness/hooks/safety.py" \
    "echo '{}' > $HOME/.agents/harness/generated-paths.json" \
    "rm $HOME/.agents/harness/generated-paths.json" \
    "mv /tmp/x $HOME/.agents/harness/self-improve-policy.json" \
    "sed -i '' s/deny/allow/ $HOME/scripts/agent-harnesses.py" \
    "cp /tmp/evil $HOME/.claude/.credentials.json" \
    "echo x >> $HOME/.ssh/id_rsa"; do
    run python3 "$SCRIPT" guard --harness omp --tool bash --command "$command"

    [ "$status" -eq 2 ]
    [ "$(printf '%s' "$output" | jq -r '.decision')" = "deny" ]
  done
}

# The guard shells out to the generator, so denying every command that merely
# names a control-plane path would deadlock the harness against itself.
@test "agent-harnesses: guard allows reads and unrelated writes near the control plane" {
  for command in \
    "python3 $HOME/scripts/agent-harnesses.py generate" \
    "python3 $HOME/scripts/agent-harnesses.py validate 2>/dev/null" \
    "cat $HOME/.agents/harness/hooks/safety.py" \
    "grep -n deny $HOME/scripts/agent-harnesses.py" \
    "echo hi > /tmp/unrelated.txt" \
    "rm -f build/out.txt"; do
    run python3 "$SCRIPT" guard --harness omp --tool bash --command "$command"

    [ "$status" -eq 0 ]
    [ "$(printf '%s' "$output" | jq -r '.decision')" = "allow" ]
  done
}

@test "agent-harnesses: provenance classifies generated, source, and generator paths" {
  run python3 "$SCRIPT" provenance --json --path "$HOME/.pi/agent/agents.json"
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.kind')" = "generated" ]

  run python3 "$SCRIPT" provenance --json --path "$HOME/.claude/commands/git/commit.md"
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.kind')" = "source" ]

  run python3 "$SCRIPT" provenance --json --path "$SCRIPT"
  [ "$status" -eq 0 ]
  [ "$(printf '%s' "$output" | jq -r '.kind')" = "generator" ]
}

# harness_paths.py is the sole source of the HARNESSES slug list
# (scripts/agent-harnesses.py imports it unconditionally). Tokenizing on
# whitespace/commas/brackets/parens catches the sequence regardless of
# single-line, one-per-line, list-literal, or tuple-literal formatting, so a
# future re-hardcoded copy is caught no matter how it is styled.
@test "agent-harnesses: harness slug list has a single definition" {
  run python3 -c "
import pathlib
pattern = ['\"claude\"', '\"codex\"', '\"opencode\"', '\"pi\"', '\"omp\"', '\"antigravity\"', '\"cursor\"', '\"grok\"']
hits = []
for root in (pathlib.Path.home() / 'scripts', pathlib.Path.home() / '.agents'):
    for path in root.rglob('*.py'):
        text = path.read_text(errors='ignore')
        for ch in ',[](){}':
            text = text.replace(ch, ' ')
        tokens = text.split()
        for i in range(len(tokens) - 7):
            if tokens[i:i+8] == pattern:
                hits.append(str(path))
                break
print('\n'.join(sorted(set(hits))))
"

  [ "$status" -eq 0 ]
  [ "$output" = "$HOME/scripts/harness_paths.py" ]
}
