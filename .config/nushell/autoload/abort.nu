export def abort [...args] {
    # Try each operation in sequence until one succeeds
    try { ^git merge --abort } catch {
        try { ^git rebase --abort } catch {
            try { ^git cherry-pick --abort } catch {
                try { ^git am --abort } catch {
                    print "No git operation to abort"
                }
            }
        }
    }
}
