# showsvn - Show .svn directories in the current directory tree
export def showsvn [...args] {
    ^find . -type d -name .svn ...$args
}
