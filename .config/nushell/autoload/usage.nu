# Dependencies:
#   functions: none
#   builtins:  none
#   externals: du

# Show disk usage for a directory (defaults to current directory)
export def usage [path?: string = "."] {
    ^du -hs $path
}
