#!/usr/bin/env bats
# claude-hooks.bats - Claude hook configuration and behavior checks

load helpers/setup

ROOT="$BATS_TEST_DIRNAME/.."
CLAUDE_SETTINGS="$ROOT/.claude/settings.json"

@test "guards: ness PreToolUse handlers are fail-closed" {
    run jq -e '
      [.hooks.PreToolUse[].hooks[]
        | select(.command | contains("guard.sh"))]
      | all(.[  ]; .onFailure == "block" and .timeout == 3)
    ' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "guards: minimum version floor is configured" {
    run jq -e '.minimumVersion == "2.1.295"' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "guards: lifecycle and formatter handlers do not carry onFailure" {
    run jq -e '
      ([.hooks.PreToolUse[].hooks[] | select(.command | contains("guard.sh"))] | length) == 2
      and ([.hooks.PreToolUse[].hooks[]
        | select((.command +"") | test("guard.sh|pre-commit-format.sh") | not)
        | objects | select(.onFailure?) ] | length) == 0
      and ([.hooks.PostToolUse[].hooks[]
        | select((.command +"") | test("guard.sh|pre-commit-format.sh") | not)
        | objects | select(.onFailure?) ] | length) == 0
      and ([.hooks.Stop[].hooks[]
        | select((.command +"") | test("guard.sh|pre-commit-format.sh") | not)
        | objects | select(.onFailure?) ] | length) == 0
    ' "$CLAUDE_SETTINGS"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "parsers: inert on invalid git inputs" {
    run python3 - "$ROOT/.claude/hooks/scripts/commit_target.py" << 'PY'
import importlib.util
import os
import sys

spec = importlib.util.spec_from_file_location("commit_target", sys.argv[1])
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
cwd = os.path.sep.join(["/base"])
assert module.commit_target("git status", cwd) is None
assert module.commit_target("git -C \"$dynamic\" commit", cwd) is None
assert module.commit_target("git -C only", cwd) is None
print("ok")
PY
    [ "$status" -eq 0 ]
    [ "$output" = "ok" ]
}

make_repo() {
    local repo="$1"
    git -C "$repo" init -q
    git -C "$repo" config user.email "test@example.com"
    git -C "$repo" config user.name "Test User"
    git -C "$repo" config commit.gpgsign false
    printf '1\n' > "$repo/idx"
    git -C "$repo" add idx
    git -C "$repo" commit -qm "init"
}

stub_formatters() {
    local repo="$1"
    cat > "$repo/justfile" << EOF
format:
    @printf 'cwd=%s\n' "\$PWD" >> "$BATS_TEST_TMPDIR/format.log"
EOF
}



@test "commit format: plain git commit target runs locally" {
    stub_just_dir="$BATS_TEST_TMPDIR/stub-just"
    mkdir -p "$stub_just_dir"
    printf '#!/usr/bin/env bash\nexec "%s" --justfile "$JUST_JUSTFILE" "$@"\n' "$(command -v just || printf '/Users/phatblat/.local/share/mise/installs/just/1.59.0/bin/just')" > "$stub_just_dir/just"
    chmod +x "$stub_just_dir/just"
    printf '#!/usr/bin/env bash\nif [ "$3" = format ]; then printf "cwd=%%s\\n" "$JUST_CWD" >> "$FORMAT_LOG"; exit 0; fi\nexec /Users/phatblat/.local/share/mise/installs/just/1.59.0/bin/just --justfile "$JUST_JUSTFILE" "$@"\n' > "$stub_just_dir/just_real" && chmod +x "$stub_just_dir/just_real"
    mv "$stub_just_dir/just_real" "$stub_just_dir/just"
    left="$BATS_TEST_TMPDIR/left"; right="$BATS_TEST_TMPDIR/right"
    mkdir -p "$left" "$right"; make_repo "$left"; make_repo "$right"
    stub_formatters "$left"
    echo "$left extra" > "$left/extra_raw.tmp"
    echo "$left/^extra_raw.tmp$" > "$left/.gitignore"
    git -C "$left" add .gitignore extra_raw.tmp
    git -C "$left" commit -qm "extra"
    : > "$BATS_TEST_TMPDIR/format.log"
    printf '{"tool_input":{"command":"git commit"},"cwd":"%s"}\n' "$left" | env PATH="$stub_just_dir:$PATH" JUST_JUSTFILE="$left/justfile" JUST_CWD="$(realpath "$left")" FORMAT_LOG="$BATS_TEST_TMPDIR/format.log" bash "$ROOT/.claude/hooks/scripts/pre-commit-format.sh"
    grep -q "^cwd=$(realpath "$left")" "$BATS_TEST_TMPDIR/format.log"
    ! git -C "$right" diff --name-only | grep -q .
}

@test "commit format: chained relative -C resolves from payload cwd" {
    stub_just_dir="$BATS_TEST_TMPDIR/stub-just"
    left="$BATS_TEST_TMPDIR/left"; right="$BATS_TEST_TMPDIR/outside"
    mkdir -p "$right/outer dir/inner repo"
    mkdir -p "$stub_just_dir"
    printf '#!/usr/bin/env bash\nif [ "$3" = format ]; then printf "cwd=%%s\\n" "$JUST_CWD" >> "$FORMAT_LOG"; exit 0; fi\nexec /Users/phatblat/.local/share/mise/installs/just/1.59.0/bin/just --justfile "$JUST_JUSTFILE" "$@"\n' > "$stub_just_dir/just"
    chmod +x "$stub_just_dir/just"
    make_repo "$right/outer dir/inner repo"
    stub_formatters "$right/outer dir/inner repo"
    git -C "$right" init -q >/dev/null 2>&1; git -C "$right" commit -qm extra >/dev/null 2>&1 || true
    : > "$BATS_TEST_TMPDIR/format.log"
    printf '{"tool_input":{"command":"git -C \\"outer dir\\" -C \\"inner repo\\" commit"},"cwd":"%s"}\n' "$right" | env PATH="$stub_just_dir:$PATH" JUST_JUSTFILE="$right/outer dir/inner repo/justfile" JUST_CWD="$(realpath "$right/outer dir/inner repo")" FORMAT_LOG="$BATS_TEST_TMPDIR/format.log" bash "$ROOT/.claude/hooks/scripts/pre-commit-format.sh"
    grep -q "^cwd=$(realpath "$right/outer dir/inner repo")" "$BATS_TEST_TMPDIR/format.log"
}

@test "commit format: dynamic git -C is inert" {
    left="$BATS_TEST_TMPDIR/left"; right="$BATS_TEST_TMPDIR/outside"
    mkdir -p "$right/left"; make_repo "$right/left"; make_repo "$right"
    : > "$BATS_TEST_TMPDIR/format.log"
    printf '{"tool_input":{"command":"git -C \"$dynamic\" commit"},"cwd":"%s"}\n' "$left" | env FORMAT_LOG="$BATS_TEST_TMPDIR/format.log" bash "$ROOT/.claude/hooks/scripts/pre-commit-format.sh"
    true
    [ ! -s "$BATS_TEST_TMPDIR/format.log" ]
}

@test "commit format: git status and prose are inert" {
    left="$BATS_TEST_TMPDIR/left"; right="$BATS_TEST_TMPDIR/outside"
    mkdir -p "$right/left"
    make_repo "$right/left"; make_repo "$right"
    : > "$BATS_TEST_TMPDIR/format.log"
    printf 'git status; # prose mentioning git commit' | \
      env FORMAT_LOG="$BATS_TEST_TMPDIR/format.log" \
      bash "$ROOT/.claude/hooks/scripts/pre-commit-format.sh"
    [ ! -s "$BATS_TEST_TMPDIR/format.log" ]
}

@test "auto format: dotfiles checkout installs hk" {
    checkout="$BATS_TEST_TMPDIR/dotfiles"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/hk.log"
    file="$checkout/payload.py"
    mkdir -p "$checkout/.claude/hooks/scripts" "$bindir"
    cp "$ROOT/.claude/hooks/scripts/auto-format.sh" "$checkout/.claude/hooks/scripts/"
    git -C "$checkout" init -q
    printf 'x\n' > "$file"
    printf '#!/usr/bin/env bash\nprintf "cwd=%%s args=%%s\\n" "$PWD" "$*" >> "%s"\n' "$log" > "$bindir/hk"
    chmod +x "$bindir/hk"
    env HOME="$checkout" PATH="$bindir:$PATH" bash "$checkout/.claude/hooks/scripts/auto-format.sh" \
      <<< "{\"tool_input\":{\"file_path\":\"$file\"}}"
    grep -q "^cwd=" "$log"
}

make_git_homedir() {
    git -C "$1" init -q
    git -C "$1" config user.email "test@example.com"
    git -C "$1" config user.name "Test User"
    git -C "$1" config commit.gpgsign false
}

@test "auto format: shared worktree file formats via hk and correct root" {
    hk_main="$BATS_TEST_TMPDIR/hk-main"
    linked="$BATS_TEST_TMPDIR/hk-wt"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/hk.log"
    mkdir -p "$hk_main/.claude/hooks/scripts" "$bindir"
    cp "$ROOT/.claude/hooks/scripts/auto-format.sh" "$hk_main/.claude/hooks/scripts/"
    git -C "$hk_main" init -q
    git -C "$hk_main" config user.email "test@example.com"
    git -C "$hk_main" config user.name "Test User"
    git -C "$hk_main" config commit.gpgsign false
    git -C "$hk_main" commit -q --allow-empty -m init
    git -C "$hk_main" worktree add -q "$linked" -b topic
    mkdir -p "$linked/src"
    printf 'x\n' > "$linked/src/status.py"
    printf '#!/usr/bin/env bash\nprintf "cwd=%%s args=%%s\\n" "$PWD" "$*" >> "%s"\n' "$log" > "$bindir/hk"
    chmod +x "$bindir/hk"
    env HOME="$linked" PATH="$bindir:$PATH" bash "$hk_main/.claude/hooks/scripts/auto-format.sh" \
      <<< "{\"tool_input\":{\"file_path\":\"$linked/src/status.py\"}}"
    grep -Eq -- "--cd .* fix .*status\.py" "$log"
}


@test "auto format: ignored files bypass all formatting" {
    unrelated="$BATS_TEST_TMPDIR/home"
    mkdir -p "$unrelated"
    make_git_homedir "$unrelated"
    bindir="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$bindir"
    log="$BATS_TEST_TMPDIR/ruff-ignore2.log"
    printf 'cache.py\n' > "$unrelated/.gitignore"
    printf 'x = 1\n' > "$unrelated/cache.py"
    printf '#!/usr/bin/env bash\nprintf "ruff args=%%s\\n" "$*" >> "%s"\n' "$log" > "$bindir/ruff"
    printf '#!/usr/bin/env bash\nprintf "hk args=%%s\\n" "$*" >> "%s"\n' "$log" > "$bindir/hk"
    chmod +x "$bindir/hk" "$bindir/ruff"
    env HOME="$unrelated" PATH="$bindir:$PATH" bash "$ROOT/.claude/hooks/scripts/auto-format.sh" \
      <<< "{\"tool_input\":{\"file_path\":\"$unrelated/cache.py\"}}"
    [ ! -s "$log" ]
}
@test "auto format: unrelated home project uses generic ruff" {
    unrelated="$BATS_TEST_TMPDIR/home"
    bindir="$BATS_TEST_TMPDIR/bin"
    log="$BATS_TEST_TMPDIR/ruff.log"
    hk_log="$BATS_TEST_TMPDIR/hk-fallback.log"
    mkdir -p "$unrelated" "$bindir"
    make_git_homedir "$unrelated"
    printf 'x = 1\n' > "$unrelated/stuff.py"
    git -C "$unrelated" add stuff.py
    : > "$log"; : > "$hk_log"
    printf '#!/usr/bin/env bash\nprintf "args=%%s\\n" "$*" >> "%s"\n' "$log" > "$bindir/ruff"
    printf '#!/usr/bin/env bash\nprintf "hk args=%%s\\n" "$*" >> "%s"\n' "$hk_log" > "$bindir/hk"
    chmod +x "$bindir/ruff" "$bindir/hk"
    env HOME="$unrelated" PATH="$bindir:$PATH" bash "$ROOT/.claude/hooks/scripts/auto-format.sh" \
      <<< "{\"tool_input\":{\"file_path\":\"$unrelated/stuff.py\"}}"
    grep -q 'args=format --quiet' "$log"
    [ ! -s "$hk_log" ]
}
