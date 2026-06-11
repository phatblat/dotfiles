# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Wrapper for git-subrepo, forwarding all arguments
export def --wrapped subrepo [...rest] {
    ^git subrepo ...$rest
}
