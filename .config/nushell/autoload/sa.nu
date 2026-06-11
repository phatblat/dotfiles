# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Short alias for git status, forwarding all arguments
export def --wrapped sa [...rest] {
    ^git status ...$rest
}
