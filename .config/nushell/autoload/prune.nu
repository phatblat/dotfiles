# prune - Prune stale remote-tracking branches (git remote prune)
export def --wrapped prune [...args] {
    ^git remote prune ...$args
}
