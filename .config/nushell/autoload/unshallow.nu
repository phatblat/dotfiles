# unshallow - Converts a shallow git repo to full
export def unshallow [...args] {
    ^git fetch --unshallow ...$args
}
