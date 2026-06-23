# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git diff-so-fancy

# Run git diff piped through diff-so-fancy for colorized output
export def --wrapped diff [...rest] {
    ^git diff --color ...$rest | ^diff-so-fancy
}
