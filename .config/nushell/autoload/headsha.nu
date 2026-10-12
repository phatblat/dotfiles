# headsha - Print the full SHA1 hash of the current HEAD commit
export def headsha [] {
    ^git rev-parse HEAD
}
