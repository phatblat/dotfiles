# Dependencies:
#   functions: none
#   builtins:  path exists
#   externals: git

# Continue an in-progress git merge, rebase, cherry-pick, or am
export def cont [...rest: string] {
    if ('.git/MERGE_HEAD' | path exists) {
        ^git commit o> /dev/null
    } else if ('.git/REBASE_HEAD' | path exists) {
        ^git rebase --continue o> /dev/null
    } else if ('.git/CHERRY_PICK_HEAD' | path exists) {
        ^git cherry-pick --continue ...$rest
    } else {
        ^git am --continue o> /dev/null
    }
}
