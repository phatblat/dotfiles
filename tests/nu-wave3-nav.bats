#!/usr/bin/env bats
# nu-wave3-nav.bats — Nushell port tests for wave-3 nav/env-mutating functions
# Functions: home, rl, mkcd, createdirs, clone_or_pull, masd, apv, gpv, mpv

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# home
# ---------------------------------------------------------------------------

@test "home: parse check" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/home.nu'"
    [ "$status" -eq 0 ]
}

@test "home: changes directory to home" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/home.nu'; home; print \$env.PWD"
    [ "$status" -eq 0 ]
    [[ "$output" == "$HOME" ]]
}

# ---------------------------------------------------------------------------
# rl
# ---------------------------------------------------------------------------

@test "rl: parse check" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/rl.nu'"
    [ "$status" -eq 0 ]
}

@test "rl: help text available" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/rl.nu'; help rl"
    [ "$status" -eq 0 ]
    [[ "$output" == *"reflog"* ]]
}

# rl is skipped-mutating (changes dir to ~/dev/www/reflog/www which may not exist)

# ---------------------------------------------------------------------------
# mkcd
# ---------------------------------------------------------------------------

@test "mkcd: parse check" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/mkcd.nu'"
    [ "$status" -eq 0 ]
}

@test "mkcd: creates directory and cds into it" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local newdir="$tmpdir/testmkcd"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/mkcd.nu'; mkcd '$newdir'; print \$env.PWD"
    [ "$status" -eq 0 ]
    [ -d "$newdir" ]
    [[ "$output" == *"testmkcd"* ]]
    rm -rf "$tmpdir"
}

@test "mkcd: creates nested directories" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    local newdir="$tmpdir/a/b/c"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/mkcd.nu'; mkcd '$newdir'; print \$env.PWD"
    [ "$status" -eq 0 ]
    [ -d "$newdir" ]
    rm -rf "$tmpdir"
}

@test "mkcd: fails with no arguments" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/mkcd.nu'; mkcd" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# createdirs
# ---------------------------------------------------------------------------

@test "createdirs: parse check" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/createdirs.nu'"
    [ "$status" -eq 0 ]
}

@test "createdirs: creates multiple directories" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/createdirs.nu'; createdirs '$tmpdir/a' '$tmpdir/b' '$tmpdir/c'"
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/a" ]
    [ -d "$tmpdir/b" ]
    [ -d "$tmpdir/c" ]
    rm -rf "$tmpdir"
}

@test "createdirs: skips existing directories" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir -p "$tmpdir/existing"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/createdirs.nu'; createdirs '$tmpdir/existing' '$tmpdir/new'"
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/existing" ]
    [ -d "$tmpdir/new" ]
    rm -rf "$tmpdir"
}

@test "createdirs: fails with no arguments" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/createdirs.nu'; createdirs" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

# ---------------------------------------------------------------------------
# clone_or_pull
# ---------------------------------------------------------------------------

@test "clone_or_pull: parse check" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/clone_or_pull.nu'"
    [ "$status" -eq 0 ]
}

@test "clone_or_pull: help text available" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/clone_or_pull.nu'; help clone_or_pull"
    [ "$status" -eq 0 ]
    [[ "$output" == *"folder"* ]]
    [[ "$output" == *"git_url"* ]]
}

@test "clone_or_pull: pulls existing repo" {
    # Hermetic origin repo on a real branch — cloning $HOME breaks in CI,
    # where actions/checkout leaves HEAD detached and `git pull` then fails
    local tmpdir
    tmpdir="$(mktemp -d)"
    git init -q -b main "$tmpdir/origin"
    git -C "$tmpdir/origin" -c user.email=test@test -c user.name=test \
        commit -q --allow-empty -m init
    git clone -q "$tmpdir/origin" "$tmpdir/copy"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/clone_or_pull.nu'; clone_or_pull '$tmpdir/copy' 'file://$tmpdir/origin'" 2>&1
    [ "$status" -eq 0 ]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# masd
# ---------------------------------------------------------------------------

@test "masd: parse check" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/createdirs.nu'; source '$NU_AUTOLOAD/clone_or_pull.nu'; source '$NU_AUTOLOAD/masd.nu'"
    [ "$status" -eq 0 ]
}

@test "masd: help text available" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/createdirs.nu'; source '$NU_AUTOLOAD/clone_or_pull.nu'; source '$NU_AUTOLOAD/masd.nu'; help masd"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mas"* ]]
}

# masd is skipped-mutating (clones/pulls remote repo)

# ---------------------------------------------------------------------------
# apv
# ---------------------------------------------------------------------------

@test "apv: parse check" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/apv.nu'"
    [ "$status" -eq 0 ]
}

@test "apv: help text available" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/apv.nu'; help apv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ApplePlatformVersions"* ]]
}

# apv is skipped-mutating (clones/pulls remote repo and changes dir)

# ---------------------------------------------------------------------------
# gpv
# ---------------------------------------------------------------------------

@test "gpv: parse check" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/nav.nu'; source '$NU_AUTOLOAD/clone.nu'; source '$NU_AUTOLOAD/pull.nu'; source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/gpv.nu'"
    [ "$status" -eq 0 ]
}

@test "gpv: help text available" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/nav.nu'; source '$NU_AUTOLOAD/clone.nu'; source '$NU_AUTOLOAD/pull.nu'; source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/gpv.nu'; help gpv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"GooglePlatformVersions"* ]]
}

# gpv is skipped-mutating (clones/pulls remote repo and changes dir)

# ---------------------------------------------------------------------------
# mpv
# ---------------------------------------------------------------------------

@test "mpv: parse check" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/mpv.nu'"
    [ "$status" -eq 0 ]
}

@test "mpv: help text available" {
    run nu --no-config-file -c \
        "source '$NU_AUTOLOAD/lg10.nu'; source '$NU_AUTOLOAD/mpv.nu'; help mpv"
    [ "$status" -eq 0 ]
    [[ "$output" == *"MicrosoftPlatformVersions"* ]]
}

# mpv is skipped-mutating (clones/pulls remote repo and changes dir)
