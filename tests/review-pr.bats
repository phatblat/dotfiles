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
  export REVIEW_PR_THREAD_ID="019f6ce4-73da-7212-bffa-b3edfc1346d8"
  export REVIEW_PR_GRAPHQL_RESPONSE='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[]}}}}}'
  export REVIEW_PR_INITIAL_HEAD="pr-head"
  export REVIEW_PR_FINAL_HEAD="pr-head"
  export REVIEW_PR_STATUS_OUTPUT=""
  export REVIEW_PR_IGNORED_OUTPUT=""
  export REVIEW_PR_RESUME_STATUS=0
  export REVIEW_PR_RESUME_INTERRUPT=0
  export REVIEW_PR_EXEC_STATUS=0
  export REVIEW_PR_EXEC_INTERRUPT=0
  export REVIEW_PR_EMIT_THREAD=1
  export REVIEW_PR_WRITE_OUTPUT=1
  export REVIEW_PR_FINAL_OUTPUT=$'## Findings\n\nNo findings.'
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

write_continue_stubs() {
  write_stub gh 'echo "gh $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$1 $2 $3" == "repo clone getditto/widgets" ]]; then
  mkdir -p "$4/.git"
elif [[ "$1 $2" == "api graphql" ]]; then
  printf "%s\n" "$REVIEW_PR_GRAPHQL_RESPONSE"
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
  write_stub codex 'echo "codex $*" >> "$REVIEW_PR_COMMAND_LOG"
if [[ "$1" == "resume" ]]; then
  [[ "$#" -eq 10 ]]
  [[ "$9" == "$REVIEW_PR_THREAD_ID" ]]
  printf "resume-prompt:%s\n" "${10}" >> "$REVIEW_PR_COMMAND_LOG"
  if [[ "$REVIEW_PR_RESUME_INTERRUPT" -eq 1 ]]; then
    kill -INT "$PPID"
    exit 0
  fi
  exit "$REVIEW_PR_RESUME_STATUS"
fi
if [[ "$REVIEW_PR_EXEC_INTERRUPT" -eq 1 ]]; then
  kill -INT "$PPID"
  exit 0
fi
if [[ "$REVIEW_PR_EXEC_STATUS" -ne 0 ]]; then
  exit "$REVIEW_PR_EXEC_STATUS"
fi
out=""
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--output-last-message" ]]; then
    out="$2"
    shift 2
  else
    shift
  fi
done
if [[ "$REVIEW_PR_EMIT_THREAD" -eq 1 ]]; then
  printf "%s\n" "{\"type\":\"thread.started\",\"thread_id\":\"$REVIEW_PR_THREAD_ID\"}"
fi
if [[ "$REVIEW_PR_WRITE_OUTPUT" -eq 1 ]]; then
  printf "%s\n" "$REVIEW_PR_FINAL_OUTPUT" > "$out"
fi'
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

@test "review-pr fish function: forwards continue arguments" {
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/scripts"
  cat > "$fake_home/scripts/review-pr.py" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@"
EOF
  chmod +x "$fake_home/scripts/review-pr.py"

  run env HOME="$fake_home" fish --no-config -c "source '$FISH_FUNCTION'; review-pr --continue widgets#123"

  [ "$status" -eq 0 ]
  [ "$output" = $'<--continue>\n<widgets#123>' ]
}

@test "review-pr nushell function: forwards continue arguments" {
  local fake_home="$BATS_TEST_TMPDIR/home"
  mkdir -p "$fake_home/scripts"
  cat > "$fake_home/scripts/review-pr.py" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@"
EOF
  chmod +x "$fake_home/scripts/review-pr.py"

  run env HOME="$fake_home" nu --no-config-file -c "source '$NU_FUNCTION'; review-pr --continue widgets#123"

  [ "$status" -eq 0 ]
  [ "$output" = $'<--continue>\n<widgets#123>' ]
}

@test "review-pr nushell function: no args prints usage" {
  run nu --no-config-file -c "source '$NU_FUNCTION'; review-pr"

  [ "$status" -eq 2 ]
  [[ "$output" == *"Usage: review-pr"* ]]
}

@test "review-pr: rejects duplicate continue flags" {
  run "$SCRIPT" --continue "widgets#123" --continue

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
  grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "codex resume" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: continues exact Codex session and retains changed worktree" {
  export REVIEW_PR_STATUS_OUTPUT=" M src/widget.ts"
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"No findings."* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  grep -q "codex exec --json --profile main --cd $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  grep -q "codex exec .*--add-dir $HOME/2ndBrain/daily-notes" "$REVIEW_PR_COMMAND_LOG"
  grep -q "codex resume --profile main --cd $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-.* --add-dir $HOME/2ndBrain/daily-notes --no-alt-screen $REVIEW_PR_THREAD_ID" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: hands filtered findings to the resumed session" {
  export REVIEW_PR_GRAPHQL_RESPONSE='{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[{"isResolved":false,"path":"src/widget.ts","line":40,"originalLine":40,"startLine":null,"originalStartLine":null}]}}}}}'
  export REVIEW_PR_FINAL_OUTPUT=$'## Findings\n\n### P1: Existing thread\n- File: `src/widget.ts`\n- Lines: 42-45\n- Problem: Already discussed\n\n### P2: New issue\n- File: `src/other.ts`\n- Lines: 20-21\n- Problem: Missing test'
  export REVIEW_PR_STATUS_OUTPUT=" M src/widget.ts"
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" != *"### P1: Existing thread"* ]]
  [[ "$output" == *"### P2: New issue"* ]]
  grep -q "### P2: New issue" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "### P1: Existing thread" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: removes an unchanged continued worktree without force" {
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" != *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains committed changes after continuation" {
  export REVIEW_PR_FINAL_HEAD="new-head"
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains ignored files created during continuation" {
  export REVIEW_PR_IGNORED_OUTPUT="!! .env"
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  grep -q "status --porcelain --ignored=matching" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains the worktree when resume fails" {
  export REVIEW_PR_RESUME_STATUS=23
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 23 ]
  [[ "$output" == *"Worktree retained:"* ]]
  [[ "$output" == *"Codex session: $REVIEW_PR_THREAD_ID"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains the worktree when resume is interrupted" {
  export REVIEW_PR_RESUME_INTERRUPT=1
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 130 ]
  [[ "$output" == *"Review interrupted"* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: safely removes the worktree when initial review fails" {
  export REVIEW_PR_EXEC_STATUS=17
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 17 ]
  [[ "$output" == *"Codex review failed with exit code 17"* ]]
  [[ "$output" != *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: safely removes the worktree when initial review is interrupted" {
  export REVIEW_PR_EXEC_INTERRUPT=1
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 130 ]
  [[ "$output" == *"Review interrupted"* ]]
  [[ "$output" != *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains the worktree when the session ID is missing" {
  export REVIEW_PR_EMIT_THREAD=0
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Codex review did not report a session ID"* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  ! grep -q "codex resume" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: rejects missing final output and retains its session" {
  export REVIEW_PR_WRITE_OUTPUT=0
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Codex review did not produce final output"* ]]
  [[ "$output" == *"Worktree retained:"* ]]
  [[ "$output" == *"Codex session: $REVIEW_PR_THREAD_ID"* ]]
  ! grep -q "codex resume" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove" "$REVIEW_PR_COMMAND_LOG"
}

@test "review-pr: retains a worktree when safe cleanup refuses" {
  export REVIEW_PR_REMOVE_FAIL=1
  write_continue_stubs

  run "$SCRIPT" --continue "widgets#123"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Worktree retained:"* ]]
  grep -q "worktree remove $REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-" "$REVIEW_PR_COMMAND_LOG"
  ! grep -q "worktree remove --force" "$REVIEW_PR_COMMAND_LOG"
  compgen -G "$REVIEW_PR_WORKTREE_ROOT/review-pr-widgets-123-*" >/dev/null
}

@test "review-pr: resets the inline Codex terminal after resume errors" {
  run python3 - "$SCRIPT" <<'PY'
import importlib.util
import subprocess
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("review_pr", sys.argv[1])
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class FakeOutput:
    def __init__(self):
        self.value = ""

    def isatty(self):
        return True

    def write(self, value):
        self.value += value

    def flush(self):
        pass


def fail(command, **_kwargs):
    raise subprocess.CalledProcessError(23, command)


output = FakeOutput()
original_stdout = module.sys.stdout
module.sys.stdout = output
module.run = fail
try:
    module.resume_codex_session(Path("/tmp/review-pr"), "thread-id", "findings")
except subprocess.CalledProcessError as error:
    assert error.returncode == 23
else:
    raise AssertionError("resume error did not propagate")
finally:
    module.sys.stdout = original_stdout

assert output.value == module.CODEX_TERMINAL_RESET
PY

  [ "$status" -eq 0 ]
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
