#!/usr/bin/env bats
# git-hooks.bats — Tests for git hooks in .config/git/hooks/

load helpers/setup

HOOKS_DIR="$HOME/.config/git/hooks"

# ---------------------------------------------------------------------------
# Helper: create a temp git repo with hooks configured
# ---------------------------------------------------------------------------
setup_test_repo() {
    local tmpdir
    tmpdir="$(mktemp -d)"
    git -C "$tmpdir" init -q
    git -C "$tmpdir" config user.email "real@example.com"
    git -C "$tmpdir" config user.name "Real User"
    git -C "$tmpdir" config core.hooksPath "$HOOKS_DIR"
    echo "initial" > "$tmpdir/init.txt"
    git -C "$tmpdir" add init.txt
    git -C "$tmpdir" commit -qm "init"
    echo "$tmpdir"
}

# ---------------------------------------------------------------------------
# pre-commit hook: test identity guard
# ---------------------------------------------------------------------------

@test "pre-commit: blocks leaked test identity in .config/git/config" {
    local tmpdir
    tmpdir="$(setup_test_repo)"
    
    # Create a .config/git directory in the test repo
    mkdir -p "$tmpdir/.config/git"
    
    # Write a config with the test identity
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
	name = Test Suite
	email = test-suite@example.com
[credential]
	helper = store
EOF
    
    # Stage the leaked config
    git -C "$tmpdir" add .config/git/config
    
    # Attempt to commit should fail
    run git -C "$tmpdir" commit -m "test commit"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "contains the test identity" ]]
    
    rm -rf "$tmpdir"
}

@test "pre-commit: blocks leaked test identity in .gitconfig" {
    local tmpdir
    tmpdir="$(setup_test_repo)"
    
    # Write a .gitconfig with the test identity
    cat > "$tmpdir/.gitconfig" << 'EOF'
[user]
	name = Test Suite
	email = test-suite@example.com
EOF
    
    # Stage the leaked config
    git -C "$tmpdir" add .gitconfig
    
    # Attempt to commit should fail
    run git -C "$tmpdir" commit -m "test commit"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "contains the test identity" ]]
    
    rm -rf "$tmpdir"
}

@test "pre-commit: allows clean git config without test identity" {
    local tmpdir
    tmpdir="$(setup_test_repo)"
    
    # Create a .config/git directory in the test repo
    mkdir -p "$tmpdir/.config/git"
    
    # Write a clean config
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
	name = Real User
	email = real@example.com
[credential]
	helper = store
EOF
    
    # Stage the clean config
    git -C "$tmpdir" add .config/git/config
    
    # Commit should succeed
    run git -C "$tmpdir" commit -m "test commit"
    [ "$status" -eq 0 ]
    
    rm -rf "$tmpdir"
}

@test "pre-commit: allows commit when config files not staged" {
    local tmpdir
    tmpdir="$(setup_test_repo)"
    
    # Create a .config/git directory with test identity but DON'T stage it
    mkdir -p "$tmpdir/.config/git"
    cat > "$tmpdir/.config/git/config" << 'EOF'
[user]
	name = Test Suite
	email = test-suite@example.com
EOF
    
    # Stage a different file
    echo "new content" > "$tmpdir/other.txt"
    git -C "$tmpdir" add other.txt
    
    # Commit should succeed (config not staged)
    run git -C "$tmpdir" commit -m "test commit"
    [ "$status" -eq 0 ]
    
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# pre-commit hook: mise config auto-format
# ---------------------------------------------------------------------------

@test "pre-commit: normalizes an unsorted mise [tools] block before committing" {
    local tmpdir
    tmpdir="$(setup_test_repo)"

    mkdir -p "$tmpdir/scripts" "$tmpdir/.config/mise"
    cp "$BATS_TEST_DIRNAME/../scripts/sort-tools.py" "$tmpdir/scripts/sort-tools.py"
    cat > "$tmpdir/.config/mise/config.toml" << 'EOF'
[tools]
zoxide = "0.10.0"
node = "26.8.1"
oh-my-pi = "18.0.10"
EOF

    git -C "$tmpdir" add .config/mise/config.toml scripts/sort-tools.py

    # Should succeed even though [tools] is unsorted going in -- the hook
    # normalizes it before the commit lands.
    run git -C "$tmpdir" commit -m "test commit"
    [ "$status" -eq 0 ]

    run git -C "$tmpdir" show HEAD:.config/mise/config.toml
    [ "$status" -eq 0 ]
    [ "$output" = $'[tools]\nnode = "26.8.1"\noh-my-pi = "18.0.10"\nzoxide = "0.10.0"' ]

    rm -rf "$tmpdir"
}
