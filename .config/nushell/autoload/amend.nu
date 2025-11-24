export def amend [...args] {
    ^git commit --verbose --amend ...$args
}
