# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Thin wrapper around git rev-parse
export def --wrapped 'rev-parse' [...rest: string] {
    ^git rev-parse ...$rest
}
