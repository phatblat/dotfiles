# Dependencies:
#   functions: none
#   builtins:  none
#   externals: bundle

# Short alias for executing gems through Bundler (bundle exec)
export def --wrapped be [...rest] {
    ^bundle exec ...$rest
}
