# Runs bundle-pull.rb ruby script
function bundle-pull
    # bundle exec ~/.dotfiles/git/bundle-pull.rb $argv

    # New logic

    # Ensure current dir is in a clean git repo
    if not git_inside_repo
        echo "This command must be run inside a git repo."
        return 1
    end

    if git_repo_dirty
        echo "The work tree is dirty, aborting."
        return 2
    end

    set -l bundle_name snapshot.bundle
    set -l hostname (hostname)
    set -l remote_hostname
    switch $hostname
        case greymatter.local
            set remote_hostname imac.local
        case imac.local
            set remote_hostname greymatter.local
        case '*'
            echo "Unknown hostname: "$hostname
            return 3
    end

    set -l username $USER
    set -l repo_path $PWD
    set -l current_branch (current-branch)

    # Create a git bundle file containing the diff of the working copy
    # to HEAD.
    ssh $username@$remote_hostname \
        # Move into repo dir
        cd $repo_path \
        pwd \
        # Clean out previous bundle, if necessary
        #
        # Snapshot
        echo "current branch: "(current-branch) \
        set -l head_sha (headsha) \
        echo "HEAD: $head_sha" \
        git stash list \
        # git stash list -p \ # verbose diff of stash
        git stash save "snapshot: "(date) \
        #
        # Returns only the SHA of the last stash (will need the next one back in history in order to restore staging area status)
        set -l snapshot_sha (git show --pretty=oneline 'refs/stash@{0}' \
            | line 1 \
            | awk '{print $1}') \
        echo "snapshot: $snapshot_sha" \
        #
        # Restore the dirty work tree
        git stash apply 'stash@{0}' \
        #
        # Create bundle
        git tag -d snapshot_end; or true \
        git tag snapshot_end $snapshot_sha \
        #
        # This requires the HEAD commit to be present in the local repo
        # TODO: figure out common ancestor
        git bundle create $bundle_name HEAD..snapshot_end \
        git bundle verify $bundle_name \
        git tag -d snapshot_end; or true

    # Download the git bundle file using SCP
    scp $username@$remote_hostname/$repo_path/$bundle_name \
        $repo_path/$bundle_name

    git bundle list-heads snapshot.bundle

    # Extract bundle
    # git cherry-pick --no-commit refs/tags/snapshot_end \
    git fetch snapshot.bundle refs/tags/snapshot_end:snapshot
    git tag before_bundle_pull
    git checkout snapshot
    git reset --mixed before_bundle_pull

    # Cleanup
    git checkout #{current_branch}
    git branch --delete snapshot
    git tag -d before_bundle_pull
    git tag -d snapshot_end
    rm $bundle_name
end
