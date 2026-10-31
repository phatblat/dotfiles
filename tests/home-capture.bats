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
[dotfiles."~/.inputrc"]
source = "$SRC/.inputrc"
mode = "symlink"
relative = false

[dotfiles."~/.vimrc"]
source = "$SRC/.vimrc"
mode = "symlink"
relative = false
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

@test "home-capture: runs against the spec home_spec.py renders" {
    python3 "$BATS_TEST_DIRNAME/../scripts/home_spec.py" generate --repo "$SRC" --source "$SRC"
    cp "$SRC/.config/mise/conf.d/dotfiles.toml" "$SBHOME/.config/mise/conf.d/dotfiles.toml"
    rm "$SBHOME/.inputrc"
    cp "$SRC/.inputrc" "$SBHOME/.inputrc"

    run sbx python3 "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "would restore ~/.inputrc" ]]
    [ ! -L "$SBHOME/.inputrc" ]
}

@test "home-capture: runs against the committed deploy spec" {
    ln -sf "$(cd "$BATS_TEST_DIRNAME/.." && pwd)/.config/mise/conf.d/dotfiles.toml" "$SBHOME/.config/mise/conf.d/dotfiles.toml"

    run sbx python3 "$SCRIPT" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" =~ "home-capture:" ]]
}

@test "home-capture: forced restore touches only the paths it checked" {
    rm "$SBHOME/.inputrc" "$SBHOME/.vimrc"
    echo "set app-edit" > "$SBHOME/.inputrc"
    ln -s /etc/hosts "$SBHOME/.vimrc"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [ "$(readlink "$SBHOME/.inputrc")" = "$SRC/.inputrc" ]
    [ "$(readlink "$SBHOME/.vimrc")" = /etc/hosts ]
}

@test "home-capture: captures a copy-class file's live bytes into the repo" {
    echo '{"seed":true}' > "$SRC/app.json"
    git -C "$SRC" add app.json
    git -C "$SRC" commit -qm "app"
    cat >> "$SBHOME/.config/mise/conf.d/dotfiles.toml" << EOF

[dotfiles."~/app.json"]
source = "$SRC/app.json"
mode = "copy"
EOF
    echo '{"seed":false,"app":"edit"}' > "$SBHOME/app.json"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "captured ~/app.json" ]]
    [ "$(cat "$SRC/app.json")" = '{"seed":false,"app":"edit"}' ]
}

@test "home-capture: leaves a copy-class entry alone when its target is a symlink" {
    echo '{"seed":true}' > "$SRC/app.json"
    git -C "$SRC" add app.json
    git -C "$SRC" commit -qm "app"
    cat >> "$SBHOME/.config/mise/conf.d/dotfiles.toml" << EOF

[dotfiles."~/app.json"]
source = "$SRC/app.json"
mode = "copy"
EOF
    echo '{"other":true}' > "$BATS_TEST_TMPDIR/elsewhere.json"
    ln -s "$BATS_TEST_TMPDIR/elsewhere.json" "$SBHOME/app.json"

    run sbx python3 "$SCRIPT"
    [ "$status" -eq 0 ]
    [[ ! "$output" =~ "captured ~/" ]]
    [ "$(cat "$SRC/app.json")" = '{"seed":true}' ]
}
