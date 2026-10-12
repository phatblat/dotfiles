# sha - Print the SHA1 of the HEAD commit
export def sha [...args] {
    ^git rev-parse HEAD ...$args
}
