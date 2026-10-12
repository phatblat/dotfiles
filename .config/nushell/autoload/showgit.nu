# showgit - Searches for .git repos recursively below the current dir
export def showgit [...args] {
    ^find . -type d -name .git ...$args
}
