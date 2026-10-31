#!/usr/bin/env bats
# home-capture.bats — Data-loss boundaries of scripts/home-capture.py
#
# Each test deploys a two-file repo into a throwaway HOME with a real
# `mise dot apply`, then replaces a deployed link the way an app would.

load helpers/setup

SCRIPT="$HOME/scripts/home-capture.py"

setup() {
    command -v mise > /dev/null || skip "mise not installed"
    SRC="$BATS_TEST_TMPDIR/src"
    SBHOME="$BATS_TEST_TMPDIR/home"
    mkdir -p "$SRC" "$SBHOME/.config/mise/conf.d"
    git -C "$SRC" init -q
    git -C "$SRC" config user.email "real@example.com"
    git -C "$SRC" config user.name "Real User"
    git -C "$SRC" config commit.gpgsign false
    echo "set a" > "$SRC/.inputrc"
    echo "set b" > "$SRC/.vimrc"
    git -C "$SRC" add .inputrc .vimrc
    git -C "$SRC" commit -qm "init"
    cat > "$SBHOME/.config/mise/conf.d/dotfiles.toml" << EOF
[dotfiles."~"]
source = "$SRC"
mode = "symlink-each"
manifest = "git"
relative = false
dot_prefix = false
exclude = []
EOF
    sbx mise dot apply --yes
    [ -L "$SBHOME/.inputrc" ]
}

sbx() {
    (cd "$SBHOME" && env HOME="$SBHOME" \
        XDG_CONFIG_HOME="$SBHOME/.config" \
        MISE_CONFIG_DIR="$SBHOME/.config/mise" \
        XDG_STATE_HOME="$BATS_TEST_TMPDIR/state" \
        MISE_STATE_DIR="$BATS_TEST_TMPDIR/state/mise" \
        MISE_CACHE_DIR="$BATS_TEST_TMPDIR/cache" \
        "$@")
}

@test "home-capture: copies a replaced link's bytes into the repo and restores the link" {
    rm "$SBHOME/.inputrc"
    echo "set app-edit" > "$SBHOME/.inputrc"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(cat "$SRC/.inputrc")" = "set app-edit" ]
    [ -L "$SBHOME/.inputrc" ]
    [ "$(readlink "$SBHOME/.inputrc")" = "$SRC/.inputrc" ]
}

@test "home-capture: refuses when both HOME and the repo changed" {
    echo "set uncommitted" >> "$SRC/.inputrc"
    rm "$SBHOME/.inputrc"
    echo "set app-edit" > "$SBHOME/.inputrc"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "conflict: .inputrc: changed in both" ]]
    [ "$(cat "$SRC/.inputrc")" = $'set a\nset uncommitted' ]
    [ ! -L "$SBHOME/.inputrc" ]
}

@test "home-capture: refuses a directory where a file belongs and leaves other files alone" {
    rm "$SBHOME/.vimrc"
    mkdir "$SBHOME/.vimrc"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "conflict: .vimrc: directory where a file belongs" ]]
    [ -d "$SBHOME/.vimrc" ]
    [ -L "$SBHOME/.inputrc" ]
}
