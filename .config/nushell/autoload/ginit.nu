# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Initialize a new git repository
export def --wrapped ginit [...rest] {
    ^git init ...$rest
}
