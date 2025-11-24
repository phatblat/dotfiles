export def amendne [...args] {
    ^git commit --verbose --amend --no-edit ...$args
}
