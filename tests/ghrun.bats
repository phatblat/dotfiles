#!/usr/bin/env bats
# ghrun.bats — GitHub Actions run watcher + job retry loop (zsh + nushell)
# Functions: ghrun, ghrun retry

load helpers/setup

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
NU_AUTOLOAD="$REPO_ROOT/.config/nushell/autoload"
ZSH_FUNCTIONS="$REPO_ROOT/.config/zsh/functions"
STUB_DIR=""
GHSTUB_STATE=""

setup() {
    STUB_DIR="$BATS_TEST_TMPDIR/stub"
    GHSTUB_STATE="$STUB_DIR/state"
    fakegh_setup
}

# ---------------------------------------------------------------------------
# Helpers: fake gh on PATH
# ---------------------------------------------------------------------------

# Fake gh driven by a state file: "attempt|status|conclusion".
#   run list  -> fixed id "123"
#   run view --json attempt,... -> state fields (tab-separated)
#   run view --json attempt -> state attempt
#   run rerun -> attempt+1, in_progress, null; resets the poll counter
#   repo view -> o/r
#   api .../attempts/N/jobs -> "999\tstatus\tconclusion" (empty conclusion when null).
#       An in_progress job flips to completed after GHSTUB_POLLS polls (default 2),
#       with conclusion GHSTUB_RERUN_CONCLUSION (default success). No wall-clock timing.
make_fake_gh() {
    cat > "$STUB_DIR/gh" <<'STUB'
#!/bin/sh
state="$GHSTUB_STATE"
dir="$(dirname "$state")"
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
            rerun) printf "%s|in_progress|null\n" "$((attempt+1))" > "$state"; echo 0 > "$dir/polls"; exit 0;;
        esac;;
    repo) echo "o/r"; exit 0;;
    api)
        printf '%s\n' "$2" >> "$dir/api.log"
        printf '%s\n' "$*" >> "$dir/api.args"
        # Honor the job selector like the real --jq filter: no match -> no output.
        [ "${GHRUN_JOB-}" = "${GHSTUB_JOB:-My Job}" ] || exit 0
        if [ "$st" = "in_progress" ]; then
            polls=$(( $(cat "$dir/polls" 2>/dev/null || echo 0) + 1 ))
            echo "$polls" > "$dir/polls"
            if [ "$polls" -ge "${GHSTUB_POLLS:-2}" ]; then
                st="completed"
                con="${GHSTUB_RERUN_CONCLUSION:-success}"
                printf "%s|%s|%s\n" "$attempt" "$st" "$con" > "$state"
            fi
        fi
        printf "999\t%s\t%s\n" "$st" "$con" | sed "s/null//"; exit 0;;
esac
exit 1
STUB
    chmod +x "$STUB_DIR/gh"
}

fakegh_setup() {
    mkdir -p "$STUB_DIR"
    make_fake_gh
    printf "1|completed|failure\n" > "$GHSTUB_STATE"
    export GHSTUB_STATE
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

@test "nu: ghrun failure and success leave the calling shell running" {
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        try { ghrun } catch { print 'caught failure' }
        print 'after failure'
        printf '1|completed|success\n' | save -f '$GHSTUB_STATE'
        ghrun
        print 'after success'
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"caught failure"* ]]
    [[ "$output" == *"after failure"* ]]
    [[ "$output" == *"after success"* ]]
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
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job 'My Job' --max 2 --until-success --interval 1
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"rerun run=123"* ]]
    [[ "$output" == *"My Job succeeded after 1 attempts"* ]]
}

@test "zsh: ghrun retry fixed-count tallies and exits 0" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job 'My Job' --max 1 --interval 1
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"Completed 1 attempts: 1 success / 0 failure"* ]]
}

@test "zsh: ghrun retry resolves --repo on every call in the same shell" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job 'My Job' --max 1 --interval 1 --repo a/b
        ghrun retry 123 --job 'My Job' --max 1 --interval 1 --repo c/d
    " 2>&1
    [ "$status" -eq 0 ]
    grep -q '^repos/a/b/actions/runs/123/' "$STUB_DIR/api.log"
    grep -q '^repos/c/d/actions/runs/123/' "$STUB_DIR/api.log"
    [ "$(tail -n 1 "$STUB_DIR/api.log" | cut -d/ -f1-3)" = "repos/c/d" ]
}

@test "nu: ghrun retry --until-success exits 0 when the rerun succeeds" {
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun retry 123 --job 'My Job' --max 2 --until-success --interval 1
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"rerun run=123"* ]]
    [[ "$output" == *"My Job succeeded after 1 attempts"* ]]
}

@test "zsh: ghrun retry passes an unusual job name via env, not jq source" {
    export GHSTUB_JOB='My "Odd" \ Job'
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun retry 123 --job '$GHSTUB_JOB' --max 2 --until-success --interval 1
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"succeeded after 1 attempts"* ]]
    ! grep -qF 'Odd' "$STUB_DIR/api.args"
}

@test "nu: ghrun retry passes an unusual job name via env, not jq source" {
    export GHSTUB_JOB='My "Odd" \ Job'
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun retry 123 --job 'My \"Odd\" \\ Job' --max 2 --until-success --interval 1
    " 2>&1
    [ "$status" -eq 0 ]
    [[ "$output" == *"succeeded after 1 attempts"* ]]
    ! grep -qF 'Odd' "$STUB_DIR/api.args"
}

# ---------------------------------------------------------------------------
# Option validation
# ---------------------------------------------------------------------------

@test "zsh: ghrun rejects non-numeric or non-positive --max and --interval" {
    for args in "--max abc" "--max 0" "--interval 0" "--interval 1.5"; do
        run env PATH="$STUB_DIR:$PATH" zsh -c "
            fpath=('$ZSH_FUNCTIONS' \$fpath)
            autoload -Uz ghrun
            ghrun retry 123 --job 'My Job' $args
        " 2>&1
        [ "$status" -eq 1 ]
        [[ "$output" == *"must be a positive integer"* ]]
    done
    [ ! -e "$STUB_DIR/api.log" ]
}

@test "zsh: ghrun watch rejects --interval 0" {
    run env PATH="$STUB_DIR:$PATH" zsh -c "
        fpath=('$ZSH_FUNCTIONS' \$fpath)
        autoload -Uz ghrun
        ghrun --interval 0
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"--interval must be a positive integer"* ]]
}

@test "nu: ghrun rejects non-positive --max and --interval" {
    for args in "--max 0" "--interval 0"; do
        run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
            source '$NU_AUTOLOAD/ghrun.nu'
            ghrun retry 123 --job 'My Job' $args
        " 2>&1
        [ "$status" -eq 1 ]
        [[ "$output" == *"must be a positive integer"* ]]
    done
    [ ! -e "$STUB_DIR/api.log" ]
}

@test "nu: ghrun watch rejects --interval 0" {
    run env PATH="$STUB_DIR:$PATH" nu --no-config-file -c "
        source '$NU_AUTOLOAD/ghrun.nu'
        ghrun --interval 0
    " 2>&1
    [ "$status" -eq 1 ]
    [[ "$output" == *"--interval must be a positive integer"* ]]
}
