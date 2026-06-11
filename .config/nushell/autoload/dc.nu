# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Diff the git staging area (git diff --cached)
export def --wrapped dc [...rest] {
    ^git diff --cached ...$rest
}
