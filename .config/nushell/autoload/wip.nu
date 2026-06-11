# Dependencies:
#   functions: git_repo_clean error-msg
#   builtins:  none
#   externals: git

# Commit all changes as a WIP commit
export def wip [] {
    if (git_repo_clean) {
        error-msg "There is nothing to commit. The working copy is clean."
        return
    }
    ^git add --all
    ^git commit -am "🚧 WIP"
}
