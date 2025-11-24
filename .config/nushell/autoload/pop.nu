export def pop [...args] {
    ^git reset --soft HEAD^ ...$args
}
