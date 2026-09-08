#!/usr/bin/env bats
# git-hooks.bats — Tests for the hk pre-commit guard script

load helpers/setup

GUARD="$HOME/scripts/git-guard-test-identity.sh"

setup_test_repo() {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "real@example.com"
    git -C "$tmpdir" config user.name "Real User"
    git -C "$tmpdir" config commit.gpgsign false
    echo "initial" > "$tmpdir/init.txt"
    git -C "$tmpdir" add init.txt
    git -C "$tmpdir" commit -qm "init"
    echo "$tmpdir"
}

@test "guard-test-identity: blocks leaked test identity in .config/git/config" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    mkdir -p "$tmpdir/.config/git"
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
    name = Test Suite
    email = test-suite@example.com
EOF
    git -C "$tmpdir" add .config/git/config

    run bash -c "cd '$tmpdir' && '$GUARD'"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "contains the test identity" ]]

    rm -rf "$tmpdir"
}

@test "guard-test-identity: blocks leaked test identity in .gitconfig" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    cat > "$tmpdir/.gitconfig" << 'EOF'
[user]
    name = Test Suite
    email = test-suite@example.com
EOF
    git -C "$tmpdir" add .gitconfig

    run bash -c "cd '$tmpdir' && '$GUARD'"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "contains the test identity" ]]

    rm -rf "$tmpdir"
}

@test "guard-test-identity: allows clean git config" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    mkdir -p "$tmpdir/.config/git"
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
    name = Real User
    email = real@example.com
EOF
    git -C "$tmpdir" add .config/git/config

    run bash -c "cd '$tmpdir' && '$GUARD'"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}

@test "guard-test-identity: allows commit when config files are not staged" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    mkdir -p "$tmpdir/.config/git"
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
    name = Test Suite
    email = test-suite@example.com
EOF
    echo "new content" > "$tmpdir/other.txt"
    git -C "$tmpdir" add other.txt

    run bash -c "cd '$tmpdir' && '$GUARD'"
    [ "$status" -eq 0 ]

    rm -rf "$tmpdir"
}
