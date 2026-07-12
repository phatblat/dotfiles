#!/usr/bin/env bats
# codex-hooks.bats - Codex-native hook compatibility checks

load helpers/setup

WRITE_GUARD="$HOME/.codex/hooks/scripts/write-guard.sh"
AUTO_FORMAT="$HOME/.codex/hooks/scripts/auto-format.sh"
AGENT_FLOW_GUARD="$HOME/.codex/hooks/scripts/agent-flow-guard.sh"
AUDIT_TASK_COMPLETE="$HOME/.codex/hooks/scripts/audit-task-complete.sh"
CODEX_CONFIG="$HOME/.codex/config.toml"
CODEX_HOOKS="$HOME/.codex/hooks.json"

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

@test "audit hook: is registered only in hooks.json" {
    run jq -e '
    .hooks.Stop[]
    | select(.name == "Task Complete Audit")
    | .hooks[]
    | select(.command == "bash '\''/Users/phatblat/.codex/hooks/scripts/audit-task-complete.sh'\''")
  ' "$CODEX_HOOKS"
    [ "$status" -eq 0 ]

    run grep -nE '^\[\[hooks\.' "$CODEX_CONFIG"
    [ "$status" -eq 1 ]
}

@test "audit hook: records the repository and current commit" {
    home="$BATS_TEST_TMPDIR/home"
    repo="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$home/.codex" "$repo"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test User"
    printf 'tracked\n' > "$repo/tracked.txt"
    git -C "$repo" add tracked.txt
    git -C "$repo" commit -qm "Initial commit"
    repo_root=$(/usr/bin/git -C "$repo" rev-parse --show-toplevel)
    commit=$(/usr/bin/git -C "$repo" rev-parse HEAD)

    run env HOME="$home" bash -c 'cd "$1" && "$2"' bash "$repo" "$AUDIT_TASK_COMPLETE"

    [ "$status" -eq 0 ]
    [ "$output" = "{}" ]
    line=$(<"$home/.codex/audit.log")
    timestamp=${line%% *}
    recorded_commit=${line##* commit=}
    [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
    [[ "$line" == "$timestamp CODEX_SESSION task_complete repo=$repo_root commit="* ]]
    [[ "$commit" == "$recorded_commit"* ]]
}

@test "codex hooks: security-guidance and warp handlers are disabled" {
    run env PYTHONPATH="$BATS_TEST_DIRNAME/helpers" python3 - "$CODEX_CONFIG" << 'PY'
import sys

from codex_config import load

config = load(sys.argv[1])

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

@test "codex hooks: plugins with incompatible hook schemas are disabled" {
    run env PYTHONPATH="$BATS_TEST_DIRNAME/helpers" python3 - "$CODEX_CONFIG" "$HOME" << 'PY'
import json
from pathlib import Path
import sys

from codex_config import load

config = load(sys.argv[1])

home = Path(sys.argv[2])
plugins = config.get("plugins", {})
known_hook_configs = {
    "hookify@claude-plugins-official": home
    / ".codex/plugins/cache/claude-plugins-official/hookify/local/hooks/hooks.json",
    "security-guidance@claude-plugins-official": home
    / ".codex/plugins/cache/claude-plugins-official/security-guidance/2.0.6/hooks/hooks.json",
}

enabled_incompatible = {}
for plugin, hooks_path in known_hook_configs.items():
    if not hooks_path.exists():
        continue
    hook_config = json.loads(hooks_path.read_text())
    unknown_top_level = sorted(set(hook_config) - {"hooks"})
    if unknown_top_level and plugins.get(plugin, {}).get("enabled", True):
        enabled_incompatible[plugin] = unknown_top_level

if enabled_incompatible:
    raise SystemExit(f"enabled plugins with Codex-incompatible hook schemas: {enabled_incompatible}")
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

@test "agent flow: hooks use codex-native guard" {
    run python3 - "$CODEX_HOOKS" << 'PY'
import json
import sys

hooks = json.load(open(sys.argv[1]))["hooks"]
expected = "bash '/Users/phatblat/.codex/hooks/scripts/agent-flow-guard.sh'"
agent_flow_commands = []

for groups in hooks.values():
    for group in groups:
        if group.get("name") != "Agent Flow Guard":
            continue
        for hook in group.get("hooks", []):
            agent_flow_commands.append(hook.get("command"))

if not agent_flow_commands:
    raise SystemExit("no Agent Flow Guard hooks found")
if any(command != expected for command in agent_flow_commands):
    raise SystemExit(f"non-codex agent flow commands: {agent_flow_commands}")
PY

    [ "$status" -eq 0 ]
}

@test "agent flow: guard uses CODEX_HOME agent-flow state" {
    codex_home="$BATS_TEST_TMPDIR/codex"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/mise.log"
    mkdir -p "$codex_home/agent-flow" "$bindir"
    printf '{}\n' > "$codex_home/agent-flow/session.json"
    printf 'console.log("agent-flow hook")\n' > "$codex_home/agent-flow/hook.js"
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >"$MISE_LOG"\n' > "$bindir/mise"
    chmod +x "$bindir/mise"

    run env CODEX_HOME="$codex_home" PATH="$bindir:$PATH" MISE_LOG="$log" AGENT_FLOW_HOOK_JS="$codex_home/agent-flow/hook.js" bash "$AGENT_FLOW_GUARD"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
    grep -F "$codex_home/agent-flow/hook.js" "$log"
}

@test "agent flow: caches empty state scans for a short TTL" {
    codex_home="$BATS_TEST_TMPDIR/codex"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/find.log"
    mkdir -p "$codex_home/agent-flow" "$bindir"
    cat > "$bindir/find" <<'SH'
#!/usr/bin/env bash
printf "%s\n" "$*" >>"$FIND_LOG"
exit 0
SH
    chmod +x "$bindir/find"

    run env CODEX_HOME="$codex_home" PATH="$bindir:$PATH" FIND_LOG="$log" LEGACY_AGENT_FLOW_DIR="$BATS_TEST_TMPDIR/no-legacy" AGENT_FLOW_NO_ACTIVE_TTL_SECONDS=60 bash "$AGENT_FLOW_GUARD"
    [ "$status" -eq 0 ]

    run env CODEX_HOME="$codex_home" PATH="$bindir:$PATH" FIND_LOG="$log" LEGACY_AGENT_FLOW_DIR="$BATS_TEST_TMPDIR/no-legacy" AGENT_FLOW_NO_ACTIVE_TTL_SECONDS=60 bash "$AGENT_FLOW_GUARD"
    [ "$status" -eq 0 ]

    [ "$(wc -l < "$log" | tr -d ' ')" -eq 1 ]
}
