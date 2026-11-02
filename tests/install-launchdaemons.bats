#!/usr/bin/env bats
# install-launchdaemons.bats — the same-file guard in the daemon installer
#
# install-launchdaemons is the system-scoped sibling of install-launchagents:
# same same-file guard, but it writes to /Library/LaunchDaemons under sudo.
# The guard matters here for the same reason it does there — cp refuses to
# copy a file onto itself, and the installer runs under `set -e`.
#
# The destination directory is overridden (DOTFILES_LAUNCH_DAEMONS_DIR) and
# sudo is stubbed, so the test exercises the guard without touching /Library.

setup() {
    REPO="$BATS_TEST_TMPDIR/repo"
    DEST="$BATS_TEST_TMPDIR/LaunchDaemons"
    BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$REPO/Library/LaunchDaemons" "$REPO/scripts" "$DEST" "$BIN"

    cp "$BATS_TEST_DIRNAME/../scripts/install-launchdaemons" "$REPO/scripts/install-launchdaemons"

    # sudo is stubbed: chown and chmod need root and are irrelevant to the
    # copy guard, and launchctl would touch the real system domain.
    cat > "$BIN/sudo" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    chown | chmod) exit 0 ;;
    launchctl) exit 0 ;;
esac
exec "$@"
STUB
    chmod +x "$BIN/sudo"

    cat > "$REPO/Library/LaunchDaemons/at.phatbl.test.plist" <<'PLIST'
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
    run env HOME="$BATS_TEST_TMPDIR" PATH="$BIN:$PATH" \
        DOTFILES_LAUNCH_DAEMONS_DIR="$1" \
        bash "$REPO/scripts/install-launchdaemons" 2>&1
}

@test "install-launchdaemons: copies the plist into the destination directory" {
    run_installer "$DEST"
    [ "$status" -eq 0 ]
    [ -f "$DEST/at.phatbl.test.plist" ]
    [[ "$output" =~ "Installing at.phatbl.test.plist" ]]
    [[ "$output" =~ "at.phatbl.test loaded" ]]
}

@test "install-launchdaemons: skips the copy when source and destination are the same file" {
    # Pointing the destination at the source directory makes source and
    # destination the same inode; cp refuses to copy a file onto itself, so
    # the guard must skip the copy.
    run_installer "$REPO/Library/LaunchDaemons"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already in place" ]]
    [[ ! "$output" =~ "are identical" ]]
    [[ "$output" =~ "at.phatbl.test loaded" ]]
}

@test "install-launchdaemons: overwrites a stale destination that is a different file" {
    run_installer "$DEST"
    [ "$status" -eq 0 ]

    # A different file at the destination is copied over, not skipped.
    echo "stale" > "$DEST/at.phatbl.test.plist"
    run_installer "$DEST"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "already in place" ]]
    grep -q "at.phatbl.test" "$DEST/at.phatbl.test.plist"
}
