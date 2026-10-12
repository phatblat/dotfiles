# showsvn - Show .svn directories in the current directory tree
export def --wrapped showsvn [...args] {
    ^find . -type d -name .svn ...$args
}
