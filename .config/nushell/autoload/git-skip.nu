# git-skip - Skip the current commit in a git rebase/cherry-pick/am
# Named `git-skip` rather than `skip` to avoid shadowing the `skip`
# pipeline builtin, which is used by `stdiff.nu`, `z.nu`, and interactive
# pipelines.
export def git-skip [] {
    try { ^git rebase --skip } catch {
        try { ^git cherry-pick --skip } catch {
            try { ^git am --skip } catch {
                print --stderr "No git operation to skip"
            }
        }
    }
}
