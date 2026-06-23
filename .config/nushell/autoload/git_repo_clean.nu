# Dependencies:
#   functions: none
#   builtins:  is-empty str trim
#   externals: git

# Returns true if the git working tree is clean (no uncommitted changes)
export def git_repo_clean []: nothing -> bool {
    (^git status --porcelain | str trim | is-empty)
}
