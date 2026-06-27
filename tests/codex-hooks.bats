#!/usr/bin/env bats
# codex-hooks.bats - Codex-native hook compatibility checks

load helpers/setup

WRITE_GUARD="$HOME/.codex/hooks/scripts/write-guard.sh"
AUTO_FORMAT="$HOME/.codex/hooks/scripts/auto-format.sh"
CODEX_CONFIG="$HOME/.codex/config.toml"

hook_input() {
    local command="$1"
    local cwd="${2:-$HOME}"

    jq -nc --arg command "$command" --arg cwd "$cwd" '{
    hook_event_name: "PreToolUse",
    tool_name: "apply_patch",
    tool_input: {command: $command},
    cwd: $cwd
  }'
}

@test "codex hooks: security-guidance and warp handlers are disabled" {
    run python3 - "$CODEX_CONFIG" << 'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as config_file:
    config = tomllib.load(config_file)

states = config["hooks"]["state"]
prefixes = (
    "security-guidance@claude-plugins-official:",
    "warp@claude-code-warp:",
)
incompatible = {
    name: state
    for name, state in states.items()
    if name.startswith(prefixes) and state.get("enabled", True)
}
if incompatible:
    raise SystemExit(f"enabled incompatible hooks: {sorted(incompatible)}")
PY

    [ "$status" -eq 0 ]
}

@test "write guard: denies protected paths in apply_patch commands" {
    patch=$'*** Begin Patch\n*** Update File: /Users/phatblat/.ssh/id_ed25519\n@@\n-old\n+new\n*** End Patch'
    input=$(hook_input "$patch")

    run bash -c 'printf "%s" "$1" | "$2"' bash "$input" "$WRITE_GUARD"

    [ "$status" -eq 0 ]
    [ "$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision')" = "deny" ]
    [[ "$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason')" == *"protected file"* ]]
}

@test "write guard: denies secrets added by apply_patch" {
    patch=$'*** Begin Patch\n*** Update File: config.txt\n@@\n-old\n+token = sk-abcdefghijklmnopqrstuvwxyz123456\n*** End Patch'
    input=$(hook_input "$patch")

    run bash -c 'printf "%s" "$1" | "$2"' bash "$input" "$WRITE_GUARD"

    [ "$status" -eq 0 ]
    [ "$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision')" = "deny" ]
    [[ "$(printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason')" == *"secret"* ]]
}

@test "write guard: ignores secrets removed by apply_patch" {
    patch=$'*** Begin Patch\n*** Update File: config.txt\n@@\n-token = sk-abcdefghijklmnopqrstuvwxyz123456\n+token = from_environment\n*** End Patch'
    input=$(hook_input "$patch")

    run bash -c 'printf "%s" "$1" | "$2"' bash "$input" "$WRITE_GUARD"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "auto format: formats every existing file changed by apply_patch" {
    workdir="$BATS_TEST_TMPDIR/project"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/prettier.log"
    mkdir -p "$workdir" "$bindir"
    printf '{}\n' > "$workdir/one.json"
    printf '{}\n' > "$workdir/two.json"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$2" >>"$FORMAT_LOG"\n' > "$bindir/prettier"
    chmod +x "$bindir/prettier"
    patch=$'*** Begin Patch\n*** Update File: one.json\n@@\n-{}\n+{"one": true}\n*** Update File: two.json\n@@\n-{}\n+{"two": true}\n*** End Patch'
    input=$(hook_input "$patch" "$workdir")

    run env PATH="$bindir:$PATH" FORMAT_LOG="$log" bash -c 'printf "%s" "$1" | "$2"' bash "$input" "$AUTO_FORMAT"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
    [ "$(wc -l < "$log" | tr -d ' ')" -eq 2 ]
    grep -Fx "$workdir/one.json" "$log"
    grep -Fx "$workdir/two.json" "$log"
}
