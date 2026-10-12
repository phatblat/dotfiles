# shortsha - Print the short SHA1 of the HEAD commit
export def shortsha [...args] {
    ^git rev-parse --short HEAD ...$args
}
