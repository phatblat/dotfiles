#!/usr/bin/env bats
# review-pr.bats — Functional tests for the review-pr helper

load helpers/setup

SCRIPT="$HOME/scripts/review-pr.py"
FISH_FUNCTION="$HOME/.config/fish/functions/review-pr.fish"
NU_FUNCTION="$HOME/.config/nushell/autoload/review-pr.nu"

setup() {
  export REVIEW_PR_GETDITTO_ROOT="$BATS_TEST_TMPDIR/getditto"
  export REVIEW_PR_WORKTREE_ROOT="$BATS_TEST_TMPDIR/worktrees"
  export REVIEW_PR_THREAD_WINDOW=5
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export REVIEW_PR_COMMAND_LOG="$BATS_TEST_TMPDIR/commands.log"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
}

write_stub() {
  local name="$1"
  local body="$2"
  cat >"$BATS_TEST_TMPDIR/bin/$name" <<EOF
#!/usr/bin/env bash
set -euo pipefail
$body
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/$name"
}

@test "review-pr: rejects non-GetDitto pull request URLs" {
  run "$SCRIPT" "https://github.com/example/widgets/pull/123"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Only getditto PRs are supported"* ]]
}

@test "review-pr fish function: no args prints usage" {
  run fish --no-config -c "source '$FISH_FUNCTION'; review-pr"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: review-pr"* ]]
}

@test "review-pr nushell function: no args prints usage" {
  run nu --no-config-file -c "source '$NU_FUNCTION'; review-pr"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: review-pr"* ]]
}

@test "review-pr: clones missing GetDitto repo and reviews a temp worktree" {
  write_stub gh 'echo "gh $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$1 $2 $3" == "repo clone getditto/widgets" ]]; then
  mkdir -p "$4/.git"
elif [[ "$1 $2" == "api graphql" ]]; then
  printf "%s\n" "{\"data\":{\"repository\":{\"pullRequest\":{\"reviewThreads\":{\"pageInfo\":{\"hasNextPage\":false,\"endCursor\":null},\"nodes\":[]}}}}}"
fi'
  write_stub git 'echo "git $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$3" == "worktree" && "$4" == "add" ]]; then
  mkdir -p "$6"
fi'
  write_stub codex 'echo "codex $*" >> "$REVIEW_PR_COMMAND_LOG"
out=""
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--output-last-message" ]]; then
    out="$2"
    shift 2
  else
    shift
  fi
done
cat > "$out" <<MARKDOWN
## Findings

### P1: Broken widget
- File: \`src/widget.ts\`
- Lines: 42-45
- Category: correctness
- Problem: Broken
- Impact: Bad
- Suggested fix: Fix it
MARKDOWN'

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"### P1: Broken widget"* ]]
  grep -q "gh repo clone getditto/widgets $REVIEW_PR_GETDITTO_ROOT/widgets" "$REVIEW_PR_COMMAND_LOG"
  grep -q "git -C $REVIEW_PR_GETDITTO_ROOT/widgets fetch origin pull/123/head:refs/remotes/origin/pr/123" "$REVIEW_PR_COMMAND_LOG"
  grep -q "codex exec --profile main --cd" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: filters findings near unresolved review threads" {
  mkdir -p "$REVIEW_PR_GETDITTO_ROOT/widgets/.git"
  write_stub gh 'echo "gh $*" >> "$REVIEW_PR_COMMAND_LOG"
printf "%s\n" "{\"data\":{\"repository\":{\"pullRequest\":{\"reviewThreads\":{\"pageInfo\":{\"hasNextPage\":false,\"endCursor\":null},\"nodes\":[{\"isResolved\":false,\"path\":\"src/widget.ts\",\"line\":40,\"originalLine\":40,\"startLine\":null,\"originalStartLine\":null},{\"isResolved\":true,\"path\":\"src/other.ts\",\"line\":7,\"originalLine\":7,\"startLine\":null,\"originalStartLine\":null}]}}}}}"
'
  write_stub git 'echo "git $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$3" == "worktree" && "$4" == "add" ]]; then
  mkdir -p "$6"
fi'
  write_stub codex 'echo "codex $*" >> "$REVIEW_PR_COMMAND_LOG"
out=""
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--output-last-message" ]]; then
    out="$2"
    shift 2
  else
    shift
  fi
done
cat > "$out" <<MARKDOWN
## Findings

### P1: Existing thread
- File: \`src/widget.ts\`
- Lines: 42-45
- Category: correctness
- Problem: Already discussed
- Impact: Noise
- Suggested fix: Already covered

### P2: New issue
- File: \`src/other.ts\`
- Lines: 20-21
- Category: test-coverage
- Problem: Missing test
- Impact: Regression risk
- Suggested test: Add one
MARKDOWN'

  run "$SCRIPT" "https://github.com/getditto/widgets/pull/123"

  [ "$status" -eq 0 ]
  [[ "$output" != *"Existing thread"* ]]
  [[ "$output" == *"### P2: New issue"* ]]
  [[ "$output" == *"Suppressed 1 finding"* ]]
}
