# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Forced add files to git staging area
export def --wrapped af [...rest] {
    ^git add --force ...$rest
}
