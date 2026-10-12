# unshallow - Converts a shallow git repo to full
export def --wrapped unshallow [...args] {
    ^git fetch --unshallow ...$args
}
