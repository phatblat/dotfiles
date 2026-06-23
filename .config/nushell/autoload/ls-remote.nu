# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Thin wrapper around git ls-remote
export def --wrapped 'ls-remote' [...rest] {
    ^git ls-remote ...$rest
}
