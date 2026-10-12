# skip - Skip the current commit in a git rebase/cherry-pick/am
export def skip [] {
    try { ^git rebase --skip } catch {
        try { ^git cherry-pick --skip } catch {
            try { ^git am --skip } catch {
                print --stderr "No git operation to skip"
            }
        }
    }
}
