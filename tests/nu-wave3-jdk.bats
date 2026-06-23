#!/usr/bin/env bats
# nu-wave3-jdk.bats — Nushell port tests for wave-3 JDK/env batch:
#   path_add, jdk_set, jdk_current, jdk, cargo_target, brew_home, mkcd

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# path_add
# ---------------------------------------------------------------------------

@test "path_add: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/path_add.nu'"
    [ "$status" -eq 0 ]
}

@test "path_add: prepends a new directory to PATH" {
    # Use a dir that exists but is not already in the default --no-config PATH
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        path_add '/Library/Java/JavaVirtualMachines'
        \$env.PATH | first 1 | get 0
    "
    [ "$status" -eq 0 ]
    [ "$output" = "/Library/Java/JavaVirtualMachines" ]
}

@test "path_add: does not duplicate if already present" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        path_add '/usr/bin'
        path_add '/usr/bin'
        \$env.PATH | where { |p| \$p == '/usr/bin' } | length
    "
    [ "$status" -eq 0 ]
    [ "$output" -le 1 ]
}

@test "path_add: prints warning for non-existent directory" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        path_add '/no/such/directory/xyz'
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Directory not found"* ]]
}

@test "path_add: empty arg exits non-zero" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        path_add ''
    " 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# jdk_set
# ---------------------------------------------------------------------------

@test "jdk_set: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
    "
    [ "$status" -eq 0 ]
}

@test "jdk_set: sets JAVA_HOME to a real JDK path" {
    JDK_PATH="$HOME/.local/share/mise/installs/java/26.0.1"
    if [ ! -d "$JDK_PATH" ]; then
        skip "JDK not installed at $JDK_PATH"
    fi
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        jdk_set '$JDK_PATH'
        print \$env.JAVA_HOME
    "
    [ "$status" -eq 0 ]
    [ "$output" = "$JDK_PATH" ]
}

@test "jdk_set: bin dir appears in PATH after call" {
    JDK_PATH="$HOME/.local/share/mise/installs/java/26.0.1"
    if [ ! -d "$JDK_PATH" ]; then
        skip "JDK not installed at $JDK_PATH"
    fi
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        jdk_set '$JDK_PATH'
        \$env.PATH | where { |p| \$p == '${JDK_PATH}/bin' } | length
    "
    [ "$status" -eq 0 ]
    [ "$output" -ge 1 ]
}

@test "jdk_set: skips validation when path is '-'" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        jdk_set '-'
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping jdk_path check"* ]]
}

@test "jdk_set: errors on non-existent path" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        jdk_set '/no/such/jdk/xyz'
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Path not found"* ]]
}

@test "jdk_set: errors when directory has no bin/java" {
    TMPDIR_PATH="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        jdk_set '$TMPDIR_PATH'
    " 2>&1
    rm -rf "$TMPDIR_PATH"
    [ "$status" -ne 0 ]
    [[ "$output" == *"No java binary"* ]]
}

# ---------------------------------------------------------------------------
# jdk_current
# ---------------------------------------------------------------------------

@test "jdk_current: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/jdk_current.nu'"
    [ "$status" -eq 0 ]
}

@test "jdk_current: prints JAVA_HOME label" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/jdk_current.nu'
        jdk_current
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"JAVA_HOME"* ]]
}

@test "jdk_current: prints 'which java' label" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/jdk_current.nu'
        jdk_current
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"which java"* ]]
}

# ---------------------------------------------------------------------------
# jdk
# ---------------------------------------------------------------------------

@test "jdk: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        source '$AUTOLOAD/jdk_current.nu'
        source '$AUTOLOAD/jdk.nu'
    "
    [ "$status" -eq 0 ]
}

@test "jdk: no args shows current JDK" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        source '$AUTOLOAD/jdk_current.nu'
        source '$AUTOLOAD/jdk.nu'
        jdk
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"JAVA_HOME"* ]]
}

@test "jdk: list subcommand outputs java_home header" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        source '$AUTOLOAD/jdk_current.nu'
        source '$AUTOLOAD/jdk.nu'
        jdk list
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"/usr/libexec/java_home"* ]] || [[ "$output" == *"JavaVirtualMachines"* ]]
}

@test "jdk: set subcommand with valid JDK sets JAVA_HOME" {
    JDK_PATH="$HOME/.local/share/mise/installs/java/26.0.1"
    if [ ! -d "$JDK_PATH" ]; then
        skip "JDK not installed at $JDK_PATH"
    fi
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/path_add.nu'
        source '$AUTOLOAD/jdk_set.nu'
        source '$AUTOLOAD/jdk_current.nu'
        source '$AUTOLOAD/jdk.nu'
        jdk set '$JDK_PATH'
        print \$env.JAVA_HOME
    "
    [ "$status" -eq 0 ]
    [ "$output" = "$JDK_PATH" ]
}

# ---------------------------------------------------------------------------
# brew_home
# ---------------------------------------------------------------------------

@test "brew_home: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
    "
    [ "$status" -eq 0 ]
}

@test "brew_home: no args prints brew prefix" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        brew_home
    "
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    [[ "$output" == *"homebrew"* ]] || [[ "$output" == *"linuxbrew"* ]] || [[ "$output" == *"local"* ]]
}

@test "brew_home: formula arg appends opt/<formula>" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        brew_home 'git'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"/opt/git"* ]]
}

@test "brew_home: sets BREW_HOME env var" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        brew_home
        \$env.BREW_HOME
    "
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

@test "brew_home: BREW_HOME is reused when already set" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        \$env.BREW_HOME = '/custom/brew'
        brew_home
    "
    [ "$status" -eq 0 ]
    [ "$output" = "/custom/brew" ]
}

# ---------------------------------------------------------------------------
# cargo_target
# ---------------------------------------------------------------------------

@test "cargo_target: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/ramdisk.nu'
        source '$AUTOLOAD/cargo_target.nu'
    "
    [ "$status" -eq 0 ]
}

@test "cargo_target: help text is available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/ramdisk.nu'
        source '$AUTOLOAD/cargo_target.nu'
        help cargo_target
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"CargoTarget"* ]] || [[ "$output" == *"RAM"* ]] || [[ "$output" == *"quiet"* ]]
}

# cargo_target is mutating (mounts RAM disk) — skip invocation in CI
# @test "cargo_target: sets CARGO_TARGET_DIR on success" — skipped-mutating

# ---------------------------------------------------------------------------
# mkcd
# ---------------------------------------------------------------------------

@test "mkcd: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/mkcd.nu'"
    [ "$status" -eq 0 ]
}

@test "mkcd: creates a directory and cds into it" {
    TMPDIR_PATH="$(mktemp -d)"
    NEW_DIR="$TMPDIR_PATH/testmkcd"
    run nu --no-config-file -c "
        source '$AUTOLOAD/mkcd.nu'
        mkcd '$NEW_DIR'
        print \$env.PWD
    "
    [ "$status" -eq 0 ]
    [ -d "$NEW_DIR" ]
    [[ "$output" == *"testmkcd"* ]]
    rm -rf "$TMPDIR_PATH"
}

@test "mkcd: no args exits non-zero" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/mkcd.nu'
        mkcd
    " 2>&1
    [ "$status" -ne 0 ]
}
