export def --wrapped amend [...args] {
    ^git commit --verbose --amend ...$args
}
