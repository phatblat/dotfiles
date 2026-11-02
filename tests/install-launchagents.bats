#!/usr/bin/env bats
# install-launchagents.bats — the same-file guard in the plist installers
#
# cp exits 1 when source and destination are the same inode, and the
# installers run under `set -e`, so a checkout at $HOME (migration phase 1)
# killed the installer on the first plist. The guard must skip the copy
# instead.
#
# The installer resolves the repo root from its own location, so each test
# runs a copy of the script placed in a throwaway repo.

setup() {
    REPO="$BATS_TEST_TMPDIR/repo"
    HOME_DIR="$BATS_TEST_TMPDIR/home"
    BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$REPO/Library/LaunchAgents" "$REPO/scripts" "$HOME_DIR" "$BIN"

    cp "$BATS_TEST_DIRNAME/../scripts/install-launchagents" "$REPO/scripts/install-launchagents"

    # launchctl is stubbed: the test is about the copy guard, not about
    # bootstrapping a real agent.
    cat > "$BIN/launchctl" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB
    chmod +x "$BIN/launchctl"

    cat > "$REPO/Library/LaunchAgents/at.phatbl.test.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>at.phatbl.test</string>
</dict>
</plist>
PLIST
}

run_installer() {
    run env HOME="$HOME_DIR" PATH="$BIN:$PATH" \
        bash "$REPO/scripts/install-launchagents" 2>&1
}

@test "install-launchagents: copies the plist into Library/LaunchAgents" {
    run_installer
    [ "$status" -eq 0 ]
    [ -f "$HOME_DIR/Library/LaunchAgents/at.phatbl.test.plist" ]
    [[ "$output" =~ "Installing at.phatbl.test.plist" ]]
    [[ "$output" =~ "at.phatbl.test loaded" ]]
}

@test "install-launchagents: skips the copy when source and destination are the same file" {
    # The repo checked out at $HOME makes the source and the destination the
    # same inode; cp refuses to copy a file onto itself.
    HOME_DIR="$REPO"

    run_installer
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already in place" ]]
    [[ ! "$output" =~ "are identical" ]]
    [[ "$output" =~ "at.phatbl.test loaded" ]]
}

@test "install-launchagents: overwrites a stale destination that is a different file" {
    run_installer
    [ "$status" -eq 0 ]

    # A different file at the destination is copied over, not skipped.
    echo "stale" > "$HOME_DIR/Library/LaunchAgents/at.phatbl.test.plist"
    run_installer
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "already in place" ]]
    grep -q "at.phatbl.test" "$HOME_DIR/Library/LaunchAgents/at.phatbl.test.plist"
}
