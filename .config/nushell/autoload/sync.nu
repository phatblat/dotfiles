# sync - Synchronizes a git repo
export def sync [] {
    if (git_repo_dirty) {
        print "Stashing changes"
        stsave
    }

    let sync_branch = "master"
    if ($sync_branch != (current_branch)) {
        ^git checkout $sync_branch
    }

    pull

    let remote_name = (remote_for_current_branch)
    prune $remote_name

    bra

    print "prompt to delete any tracking branches that have lost their remotes, gone in bra output"
}
