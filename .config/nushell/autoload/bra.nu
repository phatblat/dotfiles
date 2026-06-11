# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# List all git branches verbosely with tracking info (git branch -avv)
export def --wrapped bra [...rest] {
    ^git branch -avv ...$rest
}
