#!/usr/bin/env bats
# ghrun.bats — GitHub Actions run watcher + job retry loop (zsh + nushell)
# Functions: ghrun, ghrun retry

load helpers/setup

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
NU_AUTOLOAD="$REPO_ROOT/.config/nushell/autoload"
ZSH_FUNCTIONS="$REPO_ROOT/.config/zsh/functions"
STUB_DIR="$REPO_ROOT/.ghrun-test"
GHSTUB_STATE="$STUB_DIR/state"

setup() {
    fakegh_setup
}

teardown() {
    fakegh_teardown
}

# ---------------------------------------------------------------------------
# Helpers: fake gh on PATH
# ---------------------------------------------------------------------------

# Fake gh driven by a state file: "attempt|status|conclusion".
#   run list  -> fixed id "123"
#   run view --json attempt,... -> state fields (tab-separated)
#   run view --json attempt -> state attempt
#   run rerun -> attempt+1, in_progress, null
#   repo view -> o/r
#   api .../attempts/N/jobs -> "999\tstatus\tconclusion" (empty conclusion when null)
make_fake_gh() {
    cat > "$STUB_DIR/gh" <<'STUB'
#!/bin/sh
state="$GHSTUB_STATE"
[ -f "$state" ] || printf "1|completed|failure\n" > "$state"
IFS="|" read -r attempt st con < "$state"
case "$1" in
    run)
        case "$2" in
            view)
                case "$*" in
                    *attempt,status,conclusion*) printf "%s\t%s\t%s\n" "$attempt" "$st" "$con"; exit 0;;
                esac
                echo "$attempt"; exit 0;;
            list) echo "123"; exit 0;;
            rerun) printf "%s|in_progress|null\n" "$((attempt+1))" > "$state"; exit 0;;
        esac;;
    repo) echo "o/r"; exit 0;;
    api) printf "999\t%s\t%s\n" "$st" "$con" | sed "s/null//"; exit 0;;
esac
exit 1
STUB
    chmod +x "$STUB_DIR/gh"
}

fakegh_setup() {
    rm -rf "$STUB_DIR"
    mkdir -p "$STUB_DIR"
    make_fake_gh
    printf "1|completed|failure\n" > "$GHSTUB_STATE"
    export GHSTUB_STATE
}

fakegh_teardown() {
    rm -rf "$STUB_DIR"
}

# ---------------------------------------------------------------------------
# Parse / purity
# ---------------------------------------------------------------------------

@test "nu: ghrun.nu parses and passes purity" {
    run nu --no-config-file -c "source '$NU_AUTOLOAD/ghrun.nu'"
    [ "$status" -eq 0 ]
    run python3 "$REPO_ROOT/scripts/check-nushell-autoload.py" "$NU_AUTOLOAD/ghrun.nu"
    [ "$status" -eq 0 ]
}

@test "zsh: ghrun parses standalone" {
    run zsh -n "$ZSH_FUNCTIONS/ghrun"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------

@test "zsh: ghrun retry without --job prints usage and exits 1" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--job is required"* ]]
}

@test "nu: ghrun retry without --job prints usage and exits 1" {
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun retry
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--job is required"* ]]
}

@test "zsh: ghrun --help prints usage and exits 0" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun --help
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "zsh: ghrun rejects unknown options" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun --bogus
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"unknown option"* ]]
}

# ---------------------------------------------------------------------------
# Watch behavior (fake gh, fast path)
# ---------------------------------------------------------------------------

@test "zsh: ghrun watches latest run and exits 0 on success conclusion" {
    printf "1|completed|success\n" > "$GHSTUB_STATE"
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"attempt=1 status=completed conclusion=success"* ]]
    [[ "$output" == *"run 123 completed: success"* ]]
}

@test "zsh: ghrun exits 1 on failure conclusion" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"run 123 completed: failure"* ]]
}

@test "zsh: ghrun with no runs prints no runs found and exits 1" {
    printf '#!/bin/sh\ncase "$1 $2" in "run list") exit 0;; esac\nexit 1\n' > "$STUB_DIR/gh"
    chmod +x "$STUB_DIR/gh"
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"no runs found"* ]]
}

@test "nu: ghrun watches latest run and exits 0 on success conclusion" {
    printf "1|completed|success\n" > "$GHSTUB_STATE"
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"attempt=1 status=completed conclusion=success"* ]]
    [[ "$output" == *"run 123 completed: success"* ]]
}

@test "nu: ghrun exits 1 on failure conclusion" {
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"run 123 completed: failure"* ]]
}

@test "nu: ghrun with no runs prints no runs found and exits 1" {
    printf '#!/bin/sh\ncase "$1 $2" in "run list") exit 0;; esac\nexit 1\n' > "$STUB_DIR/gh"
    chmod +x "$STUB_DIR/gh"
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"no runs found"* ]]
}

# ---------------------------------------------------------------------------
# Retry loop (fake gh, state flips to completed mid-wait)
# ---------------------------------------------------------------------------

@test "zsh: ghrun retry --until-success exits 0 when the rerun succeeds" {
    (
        sleep 1
        printf "2|completed|success\n" > "$GHSTUB_STATE"
    ) &
    flipper=$!
    env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job 'My Job' --max 2 --until-success
    " >"$BATS_TEST_TMPDIR/out" 2>&1
    status=$?
    kill "$flipper" 2>/dev/null || true
    wait "$flipper" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "rerun run=123" "$BATS_TEST_TMPDIR/out"
    grep -q "My Job succeeded after 1 attempts" "$BATS_TEST_TMPDIR/out"
}

@test "zsh: ghrun retry fixed-count tallies and exits 0" {
    (
        sleep 1
        printf "2|completed|success\n" > "$GHSTUB_STATE"
    ) &
    flipper=$!
    env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job 'My Job' --max 1
    " >"$BATS_TEST_TMPDIR/out" 2>&1
    status=$?
    kill "$flipper" 2>/dev/null || true
    wait "$flipper" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "Completed 1 attempts: 1 success / 0 failure" "$BATS_TEST_TMPDIR/out"
}

@test "nu: ghrun retry --until-success exits 0 when the rerun succeeds" {
    (
        sleep 1
        printf "2|completed|success\n" > "$GHSTUB_STATE"
    ) &
    flipper=$!
    env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun retry 123 --job 'My Job' --max 2 --until-success
    " >"$BATS_TEST_TMPDIR/out" 2>&1
    status=$?
    kill "$flipper" 2>/dev/null || true
    wait "$flipper" 2>/dev/null || true
    [ "$status" -eq 0 ]
    grep -q "rerun run=123" "$BATS_TEST_TMPDIR/out"
    grep -q "My Job succeeded after 1 attempts" "$BATS_TEST_TMPDIR/out"
}
