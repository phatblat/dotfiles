# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Print the root path of the current git repository
export def root [] {
    ^git rev-parse --show-toplevel
}
