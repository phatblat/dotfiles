# Dependencies:
#   functions: none
#   builtins:  none
#   externals: bundle

# Short alias for installing gems using Bundler (bundle install)
export def --wrapped bi [...rest] {
    ^bundle install ...$rest
}
