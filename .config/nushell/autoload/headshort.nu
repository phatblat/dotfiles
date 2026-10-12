# headshort - Prints a 7-character abbreviated sha1 hash of the current HEAD commit
export def headshort [] {
    ^git rev-parse --short HEAD
}
