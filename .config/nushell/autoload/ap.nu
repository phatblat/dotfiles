# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Interactively stage hunks with git add --patch
export def ap [...rest: string] {
    ^git add --patch ...$rest
}
