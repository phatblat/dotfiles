# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Wrapper around git config user.name to get or set the git user name
export def --wrapped 'user.name' [...rest] {
    ^git config user.name ...$rest
}
