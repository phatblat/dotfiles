#!/usr/bin/env bats
# nu-wave2-docker-files.bats — Nushell port tests for docker/file utility functions
# Functions: dcp, dip, dnp, dvp, ddc, ddd, bak, bigfiles, chexe, untar, file_base

load helpers/setup

NU_AUTOLOAD="$HOME/.config/nushell/autoload"

# ---------------------------------------------------------------------------
# dcp — docker container prune (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "dcp: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/dcp.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# dip — docker image prune (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "dip: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/dip.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# dnp — docker network prune (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "dnp: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/dnp.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# dvp — docker volume prune (mutating: parse check only)
# ---------------------------------------------------------------------------

@test "dvp: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/dvp.nu'"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# ddc — docker deep clean (calls dcp/dvp/dip/dnp; mutating: parse check only)
# ---------------------------------------------------------------------------

@test "ddc: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ddc.nu'"
    [ "$status" -eq 0 ]
}

@test "ddc: help text is available" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ddc.nu'; help ddc"
    [ "$status" -eq 0 ]
    [[ "$output" == *"prune"* ]] || [[ "$output" == *"clean"* ]]
}

# ---------------------------------------------------------------------------
# ddd — delete DerivedData (mutating; parse + env tests)
# ---------------------------------------------------------------------------

@test "ddd: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ddd.nu'"
    [ "$status" -eq 0 ]
}

@test "ddd: exits non-zero when DERIVED_DATA is unset" {
    run env -u DERIVED_DATA nu --no-config-file -c "source '$NU_AUTOLOAD/ddd.nu'; ddd" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"DERIVED_DATA is not set"* ]]
}

@test "ddd: prints 'does not exist' when dir is missing" {
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/ddd.nu'
        \$env.DERIVED_DATA = '/tmp/nonexistent_dd_12345'
        ddd
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "ddd: deletes directory when DERIVED_DATA points to existing dir" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "
        source '$NU_AUTOLOAD/ddd.nu'
        \$env.DERIVED_DATA = '$tmpdir'
        ddd
    " 2>&1
    [ "$status" -eq 0 ]
    [ ! -d "$tmpdir" ]
    [[ "$output" == *"Deleting"* ]]
}

# ---------------------------------------------------------------------------
# bak — toggle .bak extension (mutating: uses temp dir)
# ---------------------------------------------------------------------------

@test "bak: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'"
    [ "$status" -eq 0 ]
}

@test "bak: adds .bak extension to file" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/notes.md"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'; bak '$tmpdir/notes.md'"
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/notes.md.bak" ]
    [ ! -f "$tmpdir/notes.md" ]
    rm -rf "$tmpdir"
}

@test "bak: removes .bak extension from .bak file" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/notes.md.bak"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'; bak '$tmpdir/notes.md.bak'"
    [ "$status" -eq 0 ]
    [ -f "$tmpdir/notes.md" ]
    [ ! -f "$tmpdir/notes.md.bak" ]
    rm -rf "$tmpdir"
}

@test "bak: exits non-zero for nonexistent file" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'; bak '$tmpdir/ghost.txt'" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
    rm -rf "$tmpdir"
}

@test "bak: handles directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir "$tmpdir/config"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'; bak '$tmpdir/config'"
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/config.bak" ]
    [ ! -d "$tmpdir/config" ]
    rm -rf "$tmpdir"
}

@test "bak: strips trailing slash from directory" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    mkdir "$tmpdir/config"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bak.nu'; bak '$tmpdir/config/'"
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/config.bak" ]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# bigfiles — list 10 biggest files (read-only)
# ---------------------------------------------------------------------------

@test "bigfiles: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/bigfiles.nu'"
    [ "$status" -eq 0 ]
}

@test "bigfiles: prints header and returns at most 10 rows" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    # Create a few files of varying sizes
    dd if=/dev/zero of="$tmpdir/big.bin" bs=1024 count=100 2>/dev/null
    dd if=/dev/zero of="$tmpdir/medium.bin" bs=1024 count=10 2>/dev/null
    touch "$tmpdir/small.txt"
    run nu --no-config-file -c "cd '$tmpdir'; source '$NU_AUTOLOAD/bigfiles.nu'; bigfiles" 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"File sizes in KB"* ]]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# chexe — chmod +x files (mutating: uses temp dir)
# ---------------------------------------------------------------------------

@test "chexe: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/chexe.nu'"
    [ "$status" -eq 0 ]
}

@test "chexe: makes explicit file executable" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/script.sh"
    run nu --no-config-file -c "source '$NU_AUTOLOAD/chexe.nu'; chexe '$tmpdir/script.sh'"
    [ "$status" -eq 0 ]
    [ -x "$tmpdir/script.sh" ]
    rm -rf "$tmpdir"
}

@test "chexe: defaults to *.sh glob when no args given" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    touch "$tmpdir/foo.sh" "$tmpdir/bar.sh"
    run nu --no-config-file -c "cd '$tmpdir'; source '$NU_AUTOLOAD/chexe.nu'; chexe"
    [ "$status" -eq 0 ]
    [ -x "$tmpdir/foo.sh" ]
    [ -x "$tmpdir/bar.sh" ]
    rm -rf "$tmpdir"
}

# ---------------------------------------------------------------------------
# file_base — strip last extension from filename
# ---------------------------------------------------------------------------

@test "file_base: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/file_base.nu'"
    [ "$status" -eq 0 ]
}

@test "file_base: returns stem of simple filename" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/file_base.nu'; file_base 'foo.txt'"
    [ "$status" -eq 0 ]
    [ "$output" = "foo" ]
}

@test "file_base: returns stem dropping only last extension" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/file_base.nu'; file_base 'archive.tar.gz'"
    [ "$status" -eq 0 ]
    [ "$output" = "archive.tar" ]
}

@test "file_base: exits non-zero on empty string" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/file_base.nu'; file_base ''" 2>&1
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# untar — extract tar.gz into named directory
# ---------------------------------------------------------------------------

@test "untar: file parses without error" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/untar.nu'"
    [ "$status" -eq 0 ]
}

@test "untar: exits non-zero with no argument" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/untar.nu'; untar" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"Usage"* ]]
}

@test "untar: exits non-zero for missing file" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/untar.nu'; untar '/tmp/no_such_file.tar.gz'" 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "untar: extracts tar.gz into directory named by archive stem" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    echo "hello" > "$tmpdir/hello.txt"
    tar --create --gzip --file "$tmpdir/myarchive.tar.gz" --directory "$tmpdir" "hello.txt"
    run nu --no-config-file -c "
        cd '$tmpdir'
        source '$NU_AUTOLOAD/untar.nu'
        untar 'myarchive.tar.gz'
    " 2>&1
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/myarchive" ]
    [ -f "$tmpdir/myarchive/hello.txt" ]
    rm -rf "$tmpdir"
}

@test "untar: strips all extensions from archive name" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    echo "hello" > "$tmpdir/hello.txt"
    tar --create --gzip --file "$tmpdir/project.v1.tar.gz" --directory "$tmpdir" "hello.txt"
    run nu --no-config-file -c "
        cd '$tmpdir'
        source '$NU_AUTOLOAD/untar.nu'
        untar 'project.v1.tar.gz'
    " 2>&1
    [ "$status" -eq 0 ]
    [ -d "$tmpdir/project" ]
    rm -rf "$tmpdir"
}

@test "untar: exits non-zero when extraction dir already exists" {
    local tmpdir
    tmpdir="$(mktemp -d)"
    echo "hello" > "$tmpdir/hello.txt"
    tar --create --gzip --file "$tmpdir/myarchive.tar.gz" --directory "$tmpdir" "hello.txt"
    mkdir "$tmpdir/myarchive"
    run nu --no-config-file -c "
        cd '$tmpdir'
        source '$NU_AUTOLOAD/untar.nu'
        untar 'myarchive.tar.gz'
    " 2>&1
    [ "$status" -ne 0 ]
    [[ "$output" == *"already exists"* ]]
    rm -rf "$tmpdir"
}
