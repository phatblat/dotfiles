#!/usr/bin/env bats
# gdotenv.bats — recursively find .env files and list the variable names they define
# Functions: gdotenv

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# gdotenv — grep variable names from .env files found recursively
# ---------------------------------------------------------------------------

# Builds a fixture tree that exercises every branch:
#   .env             - FOO=1, a comment, a blank line, export BAR=2
#   .env.local       - BAZ=3
#   .env.example     - SHOULD_NOT_APPEAR (excluded by name)
#   .envrc           - ALSO_NOT_APPEAR (direnv config, not a dotenv file)
#   node_modules/.env - PRUNED (excluded by directory pruning)
#   nested/deep/.env - DEEP_KEY (recursion)
_gdotenv_fixture() {
    local dir
    dir="$(mktemp -d)"
    mkdir -p "$dir/node_modules" "$dir/nested/deep"
    printf 'FOO=1\n# comment line\n\nexport BAR=2\n' >"$dir/.env"
    printf 'BAZ=3\n' >"$dir/.env.local"
    printf 'SHOULD_NOT_APPEAR=x\n' >"$dir/.env.example"
    printf 'export ALSO_NOT_APPEAR=y\n' >"$dir/.envrc"
    printf 'PRUNED=z\n' >"$dir/node_modules/.env"
    printf 'DEEP_KEY=4\n' >"$dir/nested/deep/.env"
    echo "$dir"
}

# --- nushell -----------------------------------------------------------

@test "gdotenv (nu): no-argument run lists every key" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" == *"FOO"* ]]
    [[ "$output" == *"BAR"* ]]
    [[ "$output" == *"BAZ"* ]]
    [[ "$output" == *"DEEP_KEY"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): excludes .env.example" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" != *"SHOULD_NOT_APPEAR"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): excludes .envrc" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" != *"ALSO_NOT_APPEAR"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): prunes node_modules" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" != *"PRUNED"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): recurses into nested directories" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | where file == 'nested/deep/.env' | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEEP_KEY"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): never prints values" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv"
    [ "$status" -eq 0 ]
    [[ "$output" != *"="* ]]
    [[ "$output" != *" 1 "* ]]
    [[ "$output" != *" 2 "* ]]
    [[ "$output" != *" 3 "* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): search term filters case-insensitively on key" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv a | get key | to text"
    [ "$status" -eq 0 ]
    [[ "$output" == *"BAR"* ]]
    [[ "$output" == *"BAZ"* ]]
    [[ "$output" != *"FOO"* ]]
    rm -rf "$dir"
}

@test "gdotenv (nu): search term does not match via file path" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv nested | length"
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
    rm -rf "$dir"
}

@test "gdotenv (nu): empty directory returns an empty table with status 0" {
    local dir
    dir="$(mktemp -d)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | length"
    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
    rm -rf "$dir"
}

@test "gdotenv (nu): result columns are exactly file and key" {
    local dir
    dir="$(_gdotenv_fixture)"
    run nu --no-config-file -c "cd '$dir'; source '$NU_AUTOLOAD/gdotenv.nu'; gdotenv | columns | to text"
    [ "$status" -eq 0 ]
    [[ "$output" == *"file"* ]]
    [[ "$output" == *"key"* ]]
    rm -rf "$dir"
}

# --- zsh -----------------------------------------------------------------

@test "gdotenv (zsh): no-argument run lists every key" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"FOO"* ]]
    [[ "$output" == *"BAR"* ]]
    [[ "$output" == *"BAZ"* ]]
    [[ "$output" == *"DEEP_KEY"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): excludes .env.example" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" != *"SHOULD_NOT_APPEAR"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): excludes .envrc" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" != *"ALSO_NOT_APPEAR"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): prunes node_modules" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" != *"PRUNED"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): recurses into nested directories" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"nested/deep/.env:DEEP_KEY"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): never prints values" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -eq 0 ]
    [[ "$output" != *"=1"* ]]
    [[ "$output" != *"=2"* ]]
    [[ "$output" != *"=3"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): search term filters case-insensitively on key" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv' a"
    [ "$status" -eq 0 ]
    [[ "$output" == *"BAR"* ]]
    [[ "$output" == *"BAZ"* ]]
    [[ "$output" != *"FOO"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): search term does not match via file path" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv' nested"
    [ "$status" -ne 0 ]
    rm -rf "$dir"
}

@test "gdotenv (zsh): exits non-zero with stderr message in an empty directory" {
    local dir
    dir="$(mktemp -d)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv'"
    [ "$status" -ne 0 ]
    [[ "$output" == *"no .env files"* ]]
    rm -rf "$dir"
}

@test "gdotenv (zsh): exits non-zero when search term matches nothing" {
    local dir
    dir="$(_gdotenv_fixture)"
    run bash -c "cd '$dir' && zsh --no-rcs '$HOME/.config/zsh/functions/gdotenv' zzz_no_match"
    [ "$status" -ne 0 ]
    [[ "$output" == *"no variables matching"* ]]
    rm -rf "$dir"
}
