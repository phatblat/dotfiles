# Dependencies:
#   functions: review-pr
#   builtins:  none
#   externals: none

# rpr - Alias for review-pr
export def --wrapped rpr [...rest: string] {
    review-pr ...$rest
}
