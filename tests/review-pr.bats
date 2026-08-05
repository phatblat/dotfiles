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
  export REVIEW_PR_GRAPHQL_RESPONSE='{"data":{"repository":{"pullRequest":{"baseRefName":"release/4.0","reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[]}}}}}'
  export REVIEW_PR_GRAPHQL_RESPONSE_2=""
  export REVIEW_PR_INITIAL_HEAD="pr-head"
  export REVIEW_PR_FINAL_HEAD="pr-head"
  export REVIEW_PR_STATUS_OUTPUT=""
  export REVIEW_PR_IGNORED_OUTPUT=""
  export REVIEW_PR_OMP_STATUS=0
  export REVIEW_PR_OMP_INTERRUPT=0
  export REVIEW_PR_REMOVE_FAIL=0
  export REVIEW_PR_HEAD_READS="$BATS_TEST_TMPDIR/head-reads"
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

write_review_stubs() {
  write_stub gh 'echo "gh $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$1 $2 $3" == "repo clone getditto/widgets" ]]; then
  mkdir -p "$4/.git"
elif [[ "$1 $2" == "api graphql" ]]; then
  if [[ " $* " == *" after="* && -n "$REVIEW_PR_GRAPHQL_RESPONSE_2" ]]; then
    printf "%s\n" "$REVIEW_PR_GRAPHQL_RESPONSE_2"
  else
    printf "%s\n" "$REVIEW_PR_GRAPHQL_RESPONSE"
  fi
fi'
  write_stub git 'echo "git $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$3" == "worktree" && "$4" == "add" ]]; then
  mkdir -p "$6"
elif [[ "$3" == "rev-parse" && "$4" == "HEAD" ]]; then
  reads=0
  if [[ -f "$REVIEW_PR_HEAD_READS" ]]; then
    reads=$(<"$REVIEW_PR_HEAD_READS")
  fi
  reads=$((reads + 1))
  printf "%s\n" "$reads" > "$REVIEW_PR_HEAD_READS"
  if [[ "$reads" -eq 1 ]]; then
    printf "%s\n" "$REVIEW_PR_INITIAL_HEAD"
  else
    printf "%s\n" "$REVIEW_PR_FINAL_HEAD"
  fi
elif [[ "$3" == "status" && "$4" == "--porcelain" ]]; then
  printf "%s" "$REVIEW_PR_STATUS_OUTPUT"
  if [[ " $* " == *" --ignored=matching "* ]]; then
    printf "%s" "$REVIEW_PR_IGNORED_OUTPUT"
  fi
elif [[ "$3" == "worktree" && "$4" == "remove" && "$REVIEW_PR_REMOVE_FAIL" -eq 1 ]]; then
  exit 1
fi'
  write_stub omp 'printf "omp-arg:<%s>\n" "$@" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$REVIEW_PR_OMP_INTERRUPT" -eq 1 ]]; then
  kill -INT "$PPID"
  exit 0
fi
exit "$REVIEW_PR_OMP_STATUS"'
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
  [[ "$output" != *"--continue"* ]]
}

@test "review-pr fish function: forwards the PR reference" {
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/scripts"
  cat >"$fake_home/scripts/review-pr.py" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@"
EOF
  chmod +x "$fake_home/scripts/review-pr.py"

  run env HOME="$fake_home" fish --no-config -c "source '$FISH_FUNCTION'; review-pr widgets#123"

  [ "$status" -eq 0 ]
  [ "$output" = "<widgets#123>" ]
}

@test "review-pr nushell function: forwards the PR reference" {
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/scripts"
  cat >"$fake_home/scripts/review-pr.py" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@"
EOF
  chmod +x "$fake_home/scripts/review-pr.py"

  run env HOME="$fake_home" nu --no-config-file -c "source '$NU_FUNCTION'; review-pr widgets#123"

  [ "$status" -eq 0 ]
  [ "$output" = "<widgets#123>" ]
}

@test "review-pr nushell function: no args prints usage" {
  run nu --no-config-file -c "source '$NU_FUNCTION'; review-pr"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: review-pr"* ]]
  [[ "$output" != *"--continue"* ]]
}

@test "review-pr: rejects the removed continue option" {
  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: review-pr"* ]]
  [[ "$output" != *"[--continue]"* ]]
}

@test "review-pr: clones, fetches both refs, and starts foreground OMP" {
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  grep -q "gh repo clone getditto/widgets $REVIEW_PR_GETDITTO_ROOT/widgets" "$REVIEW_PR_COMMAND_LOG"
  grep -q "git -C $REVIEW_PR_GETDITTO_ROOT/widgets fetch origin pull/123/head:refs/remotes/origin/pr/123 release/4.0:refs/remotes/origin/release/4.0" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<--cwd>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<--add-dir>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<$HOME/2ndBrain/daily-notes>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<--model>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<openai-codex/gpt-5.6-terra>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<--thinking>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<high>" "$REVIEW_PR_COMMAND_LOG"
  grep -q "omp-arg:<--no-prewalk>" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "omp-arg:<-p>" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "omp-arg:<--print>" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q '^codex ' "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: supplies explicit PR, base, and review-only startup prompt" {
  export REVIEW_PR_GRAPHQL_RESPONSE='{"data":{"repository":{"pullRequest":{"baseRefName":"release/4.0","reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[{"isResolved":false,"path":"src/quote file.ts","line":40,"originalLine":40,"startLine":7,"originalStartLine":11}]}}}}}'
  write_review_stubs

  run "$SCRIPT" "https://github.com/getditto/widgets/pull/123?ignored=true"

  [ "$status" -eq 0 ]
  grep -q '^omp-arg:</skill:review Review https://github.com/getditto/widgets/pull/123 against origin/release/4.0\.' "$REVIEW_PR_COMMAND_LOG"
  grep -q 'review-only: do not edit files, commit, push, or post GitHub comments' "$REVIEW_PR_COMMAND_LOG"
  grep -Fq '"path":"src/quote file.ts","lines":[7,11,40]' "$REVIEW_PR_COMMAND_LOG"
  grep -Fq 'within ±5 lines' "$REVIEW_PR_COMMAND_LOG"
  grep -q 'remain interactive for follow-up' "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: paginates unresolved threads into the startup prompt" {
  export REVIEW_PR_GRAPHQL_RESPONSE='{"data":{"repository":{"pullRequest":{"baseRefName":"main","reviewThreads":{"pageInfo":{"hasNextPage":true,"endCursor":"next-page"},"nodes":[{"isResolved":false,"path":"src/first.ts","line":12}]}}}}}'
  export REVIEW_PR_GRAPHQL_RESPONSE_2='{"data":{"repository":{"pullRequest":{"baseRefName":"main","reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[{"isResolved":false,"path":"src/second.ts","originalLine":27},{"isResolved":true,"path":"src/resolved.ts","line":9}]}}}}}'
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [ "$(grep -c 'gh api graphql' "$REVIEW_PR_COMMAND_LOG")" -eq 2 ]
  grep -Fq '"path":"src/first.ts","lines":[12]' "$REVIEW_PR_COMMAND_LOG"
  grep -Fq '"path":"src/second.ts","lines":[27]' "$REVIEW_PR_COMMAND_LOG"
  ! grep -Fq 'src/resolved.ts' "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: removes an unchanged worktree without force" {
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" != *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains an interactively edited worktree" {
  export REVIEW_PR_STATUS_OUTPUT=" M src/widget.ts"
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains commits made during follow-up" {
  export REVIEW_PR_FINAL_HEAD="new-head"
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains ignored files made during follow-up" {
  export REVIEW_PR_IGNORED_OUTPUT="!! .env"
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  grep -q "status --porcelain --ignored=matching" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains the worktree when OMP fails" {
  export REVIEW_PR_OMP_STATUS=23
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 23 ]
  [[ "$output" == *"Command failed (23): omp"* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains the worktree when OMP is interrupted" {
  export REVIEW_PR_OMP_INTERRUPT=1
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 130 ]
  [[ "$output" == *"Review interrupted"* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains a worktree when safe cleanup refuses" {
  export REVIEW_PR_REMOVE_FAIL=1
  write_review_stubs

  run "$SCRIPT" "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
  compgen -G "$REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-*" >/dev/null
}
