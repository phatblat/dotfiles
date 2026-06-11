# Dependencies:
#   functions: none
#   builtins:  none
#   externals: git

# Skip the current commit in a git rebase, cherry-pick, or am operation
export def gskip [] {
    try {
        ^git rebase --skip
    } catch {
        try {
            ^git cherry-pick --skip
        } catch {
            ^git am --skip
        }
    }
}
