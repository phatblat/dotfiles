# Dependencies:
#   functions: none
#   builtins:  none
#   externals: bundle

# Update gems in the bundle (bundle update)
export def --wrapped bu [...rest] {
    ^bundle update ...$rest
}
