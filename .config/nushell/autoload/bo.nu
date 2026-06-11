# Dependencies:
#   functions: none
#   builtins:  none
#   externals: bundle

# List outdated gems in the bundle
export def --wrapped bo [...rest] {
    ^bundle outdated ...$rest
}
