# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# List files deleted from git history
export def deleted [] {
    ^git log --diff-filter=D --summary
}
