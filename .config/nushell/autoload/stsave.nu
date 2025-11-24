export def stsave [...args] {
    ^git stash save --include-untracked ...$args
}
