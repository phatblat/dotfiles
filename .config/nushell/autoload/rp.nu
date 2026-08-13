# Dependencies:
#   functions: review-pr
#   builtins:  none
#   externals: none

# rp - Alias for review-pr
export def --wrapped rp [...rest: string] {
    review-pr ...$rest
}
