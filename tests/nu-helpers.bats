#!/usr/bin/env bats
# nu-helpers.bats — Tests for wave-0 shared helper nushell functions:
#   error-msg, edit, is_mac, is_linux, nav, rev-parse

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# error-msg
# ---------------------------------------------------------------------------

@test "error-msg: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/error-msg.nu'"
    [ "$status" -eq 0 ]
}

@test "error-msg: prints message to stderr" {
    run nu --no-config-file -c "source '$AUTOLOAD/error-msg.nu'; error-msg 'hello world'" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"hello world"* ]]
}

@test "error-msg: joins multiple args with space" {
    run nu --no-config-file -c "source '$AUTOLOAD/error-msg.nu'; error-msg 'foo' 'bar'" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"foo bar"* ]]
}

# ---------------------------------------------------------------------------
# edit
# ---------------------------------------------------------------------------

@test "edit: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'"
    [ "$status" -eq 0 ]
}

@test "edit: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/edit.nu'; help edit"
    [ "$status" -eq 0 ]
    [[ "$output" == *"editor"* ]]
}

# ---------------------------------------------------------------------------
# is_mac
# ---------------------------------------------------------------------------

@test "is_mac: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_mac.nu'"
    [ "$status" -eq 0 ]
}

@test "is_mac: returns bool true on macOS" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_mac.nu'; is_mac | into string"
    [ "$status" -eq 0 ]
    [ "$output" = "true" ]
}

@test "is_mac: return value is a boolean" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_mac.nu'; is_mac | describe"
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

# ---------------------------------------------------------------------------
# is_linux
# ---------------------------------------------------------------------------

@test "is_linux: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_linux.nu'"
    [ "$status" -eq 0 ]
}

@test "is_linux: returns bool false on macOS" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_linux.nu'; is_linux | into string"
    [ "$status" -eq 0 ]
    [ "$output" = "false" ]
}

@test "is_linux: return value is a boolean" {
    run nu --no-config-file -c "source '$AUTOLOAD/is_linux.nu'; is_linux | describe"
    [ "$status" -eq 0 ]
    [ "$output" = "bool" ]
}

# ---------------------------------------------------------------------------
# nav
# ---------------------------------------------------------------------------

@test "nav: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/nav.nu'"
    [ "$status" -eq 0 ]
}

setup_nav() {
    TEST_DIR="$(mktemp -d)"
}

teardown_nav() {
    rm -rf "$TEST_DIR"
}

@test "nav: changes to existing directory" {
    TEST_DIR="$(mktemp -d)"
    run nu --no-config-file -c "source '$AUTOLOAD/nav.nu'; nav '$TEST_DIR'; print \$env.PWD"
    [ "$status" -eq 0 ]
    # Resolve symlinks for comparison (macOS /tmp -> /private/tmp)
    expected="$(cd "$TEST_DIR" && pwd -P)"
    [[ "$output" == *"$expected"* ]] || [[ "$output" == *"$TEST_DIR"* ]]
    rm -rf "$TEST_DIR"
}

@test "nav: creates missing directory and cds into it" {
    TEST_DIR="$(mktemp -d)"
    NEW_DIR="$TEST_DIR/newsubdir"
    run nu --no-config-file -c "source '$AUTOLOAD/nav.nu'; nav '$NEW_DIR'; print \$env.PWD"
    [ "$status" -eq 0 ]
    [ -d "$NEW_DIR" ]
    [[ "$output" == *"newsubdir"* ]]
    rm -rf "$TEST_DIR"
}

@test "nav: missing arg (empty string) exits non-zero and prints usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/nav.nu'; nav ''"  2>&1
    # empty string triggers the is-empty branch; error make exits non-zero
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: nav dir"* ]]
}

@test "nav: no arg (optional param absent) exits non-zero and prints usage" {
    run nu --no-config-file -c "source '$AUTOLOAD/nav.nu'; nav"  2>&1
    # matches original fish contract: return 1 on missing dir
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: nav dir"* ]]
}

# ---------------------------------------------------------------------------
# rev-parse
# ---------------------------------------------------------------------------

@test "rev-parse: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/rev-parse.nu'"
    [ "$status" -eq 0 ]
}

@test "rev-parse: returns HEAD sha in dotfiles repo" {
    run nu --no-config-file -c "source '$AUTOLOAD/rev-parse.nu'; rev-parse HEAD"
    [ "$status" -eq 0 ]
    # SHA is a 40-char hex string
    [[ "$output" =~ ^[0-9a-f]{40}$ ]]
}

@test "rev-parse: --abbrev-ref HEAD returns branch name" {
    run nu --no-config-file -c "source '$AUTOLOAD/rev-parse.nu'; rev-parse --abbrev-ref HEAD"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
