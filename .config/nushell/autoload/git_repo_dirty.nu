# Dependencies:
#   functions: git_repo_clean
#   builtins:  none
#   externals: none

# Returns true if the git working tree is dirty (has uncommitted changes)
export def git_repo_dirty []: nothing -> bool {
    not (git_repo_clean)
}
