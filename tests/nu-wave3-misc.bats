#!/usr/bin/env bats
# nu-wave3-misc.bats — Nushell port tests for wave-3 misc batch:
#   ap, toggle_wait, br, mdp, mkcd, shell_add, shell_switch, shell_choose, xcv

load helpers/setup

AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# ap
# ---------------------------------------------------------------------------

@test "ap: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/ap.nu'"
    [ "$status" -eq 0 ]
}

@test "ap: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/ap.nu'; help ap"
    [ "$status" -eq 0 ]
    [[ "$output" == *"patch"* ]]
}

# ---------------------------------------------------------------------------
# toggle_wait
# ---------------------------------------------------------------------------

@test "toggle_wait: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/toggle_wait.nu'"
    [ "$status" -eq 0 ]
}

@test "toggle_wait: sets EDITOR with wait flag when VISUAL is empty" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/toggle_wait.nu'
        \$env.EDITOR_CLI = 'nano'
        \$env.WAIT_FLAG_CLI = '--wait'
        \$env.EDITOR_GUI = 'zed'
        \$env.WAIT_FLAG_GUI = '--wait'
        \$env.VISUAL = ''
        toggle_wait on
        print \$env.EDITOR
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"nano"* ]]
    [[ "$output" == *"--wait"* ]]
}

@test "toggle_wait: sets VISUAL with wait flag when VISUAL is set" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/toggle_wait.nu'
        \$env.EDITOR_CLI = 'nano'
        \$env.WAIT_FLAG_CLI = '--wait'
        \$env.EDITOR_GUI = 'zed'
        \$env.WAIT_FLAG_GUI = '--wait'
        \$env.VISUAL = 'zed'
        toggle_wait on
        print \$env.VISUAL
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"zed"* ]]
    [[ "$output" == *"--wait"* ]]
}

@test "toggle_wait: off removes wait flag from EDITOR" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/toggle_wait.nu'
        \$env.EDITOR_CLI = 'nano'
        \$env.WAIT_FLAG_CLI = '--wait'
        \$env.VISUAL = ''
        toggle_wait off
        print \$env.EDITOR
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"nano"* ]]
    [[ "$output" != *"--wait"* ]]
}

@test "toggle_wait: invalid state errors" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/toggle_wait.nu'
        \$env.VISUAL = ''
        toggle_wait bogus
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: toggle_wait"* ]]
}

@test "toggle_wait: env mutation persists to caller" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/toggle_wait.nu'
        \$env.EDITOR_CLI = 'nano'
        \$env.WAIT_FLAG_CLI = '--wait'
        \$env.VISUAL = ''
        toggle_wait on
        \$env.EDITOR
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"--wait"* ]]
}

# ---------------------------------------------------------------------------
# br
# ---------------------------------------------------------------------------

@test "br: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/br.nu'"
    [ "$status" -eq 0 ]
}

@test "br: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/br.nu'; help br"
    [ "$status" -eq 0 ]
    [[ "$output" == *"broot"* ]]
}

# ---------------------------------------------------------------------------
# mdp
# ---------------------------------------------------------------------------

@test "mdp: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/mdp.nu'"
    [ "$status" -eq 0 ]
}

@test "mdp: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/mdp.nu'; help mdp"
    [ "$status" -eq 0 ]
}

@test "mdp: cd persists in caller (def --env)" {
    # Only test if ~/dev/mdp exists
    if [ ! -d "$HOME/dev/mdp" ]; then
        skip "~/dev/mdp does not exist on this machine"
    fi
    run nu --no-config-file -c "
        source '$AUTOLOAD/mdp.nu'
        mdp
        \$env.PWD
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"mdp"* ]]
}

# ---------------------------------------------------------------------------
# mkcd
# ---------------------------------------------------------------------------

@test "mkcd: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/mkcd.nu'"
    [ "$status" -eq 0 ]
}

@test "mkcd: creates dir and cds into it" {
    TEST_DIR="$(mktemp -d)"
    NEW_DIR="$TEST_DIR/newsubdir"
    run nu --no-config-file -c "
        source '$AUTOLOAD/mkcd.nu'
        mkcd '$NEW_DIR'
        \$env.PWD
    "
    [ "$status" -eq 0 ]
    [ -d "$NEW_DIR" ]
    [[ "$output" == *"newsubdir"* ]]
    rm -rf "$TEST_DIR"
}

@test "mkcd: no args exits non-zero" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/mkcd.nu'
        mkcd
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage: mkcd"* ]]
}

@test "mkcd: does not cd when last arg is a flag" {
    TEST_DIR="$(mktemp -d)"
    ORIG_PWD="$TEST_DIR"
    run nu --no-config-file -c "
        cd '$TEST_DIR'
        source '$AUTOLOAD/mkcd.nu'
        mkcd '$TEST_DIR/flagtest' '-p'
        \$env.PWD
    "
    [ "$status" -eq 0 ]
    # Should NOT have changed to flagtest (last arg was -p flag)
    [[ "$output" != *"flagtest"* ]]
    rm -rf "$TEST_DIR"
}

# ---------------------------------------------------------------------------
# shell_add
# ---------------------------------------------------------------------------

@test "shell_add: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        source '$AUTOLOAD/shell_add.nu'
    "
    [ "$status" -eq 0 ]
}

@test "shell_add: help text is available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        source '$AUTOLOAD/shell_add.nu'
        help shell_add
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"shell"* ]]
}

# ---------------------------------------------------------------------------
# shell_switch
# ---------------------------------------------------------------------------

@test "shell_switch: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/shell_switch.nu'
    "
    [ "$status" -eq 0 ]
}

@test "shell_switch: help text is available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/shell_switch.nu'
        help shell_switch
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"shell"* ]]
}

# ---------------------------------------------------------------------------
# shell_choose
# ---------------------------------------------------------------------------

@test "shell_choose: parse check" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/shell_add.nu'
        source '$AUTOLOAD/shell_switch.nu'
        source '$AUTOLOAD/shell_choose.nu'
    "
    [ "$status" -eq 0 ]
}

@test "shell_choose: help text is available" {
    run nu --no-config-file -c "
        source '$AUTOLOAD/error-msg.nu'
        source '$AUTOLOAD/is_mac.nu'
        source '$AUTOLOAD/is_linux.nu'
        source '$AUTOLOAD/brew_home.nu'
        source '$AUTOLOAD/user_is_admin.nu'
        source '$AUTOLOAD/shell_add.nu'
        source '$AUTOLOAD/shell_switch.nu'
        source '$AUTOLOAD/shell_choose.nu'
        help shell_choose
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"shell"* ]]
}

# ---------------------------------------------------------------------------
# xcv
# ---------------------------------------------------------------------------

@test "xcv: parse check" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcv.nu'"
    [ "$status" -eq 0 ]
}

@test "xcv: help text is available" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcv.nu'; help xcv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Xcode"* ]]
}

@test "xcv: runs without error" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcv.nu'; xcv" 2>&1
    [ "$status" -eq 0 ]
}

@test "xcv: -s flag returns version string only" {
    run nu --no-config-file -c "source '$AUTOLOAD/xcv.nu'; xcv --short" 2>&1
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
