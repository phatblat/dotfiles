# showgit - Searches for .git repos recursively below the current dir
export def --wrapped showgit [...args] {
    ^find . -type d -name .git ...$args
}
