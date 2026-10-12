# sha - Print the SHA1 of the HEAD commit
export def --wrapped sha [...args] {
    ^git rev-parse HEAD ...$args
}
