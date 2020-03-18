# Creates a git bundle containing any changes in the working copy and index
# that haven't been committed.
function git_bundle_create
    set -l bundle_name snapshot.bundle
    set -l repo_path $PWD
    set -l current_branch (current_branch)

    # Move into repo dir
    cd $repo_path
    pwd

    # Clean out previous bundle, if necessary

    # Snapshot
    echo "current branch: $current_branch"
    set -l head_sha (headsha)
    echo "HEAD: $head_sha"
    git stash list
    # git stash list -p # verbose diff of stash
    git stash save --include-untracked "snapshot: "(date)

    # Returns only the SHA of the last stash (will need the next one back in history in order to restore staging area status)
    set -l snapshot_sha (git show --pretty=oneline 'refs/stash@{0}' \
        | line 1 \
        | awk '{print $1}')
    echo "snapshot: $snapshot_sha"

    # Restore the dirty work tree
    # git stash apply 'stash@{0}'

    # Create bundle
    git tag -d snapshot_end 2>/dev/null
    git tag snapshot_end $snapshot_sha

    # This requires the HEAD commit to be present in the local repo
    # TODO: figure out common ancestor
    git bundle create $bundle_name HEAD..snapshot_end
    git bundle verify $bundle_name
    git tag -d snapshot_end
    or true
end
