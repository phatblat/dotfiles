# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Wrapper around git config user.email to get or set the git user email
export def --wrapped 'user.email' [...rest] {
    ^git config user.email ...$rest
}
