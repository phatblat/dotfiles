# Migrated from bundle-pull.rb ruby script
function bundle-pull \
        --description='Copies a dirty working copy from one host to another.'

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
    set -l local_username $USER
    set -l local_hostname (hostname)
    set -l remote_username
    set -l remote_hostname
    switch $local_hostname
        case tredecim.local
            set remote_hostname octodec.local
            set remote_username phatblat
        case octodec.local
            set remote_hostname tredecim.local
            set remote_username phatblat
        case '*'
            echo "Unknown hostname: $local_hostname"
            return 3
    end

    # Use a path relative to HOME to avoid user mismatches
    set -l repo_path (realpath --relative-to=$HOME $PWD)
    set -l current_branch (current_branch)

    repeatchar -

    # Remote
    echo "Creating bundle on $remote_hostname:$repo_path/$bundle_name"
    echo

    # Create a git bundle file containing the diff of the working copy to HEAD.
    ssh $remote_username@$remote_hostname "cd '$repo_path'; and git_bundle_create"

    if test $status -ne 0
        return $status
    end

    repeatchar -

    echo "Downloading bundle to $local_hostname:$repo_path/$bundle_name"
    echo

    set -l source $remote_username@$remote_hostname:$repo_path/$bundle_name
    set -l destination ~/$repo_path/$bundle_name

    # rync preserves paths, scp doesn't
    rsync --archive \
        --recursive \
        --compress \
        --verbose \
        $source \
        $destination

    if test $status -ne 0
        return $status
    end

    # Delete the bundle from the remote after successful transfer
    ssh $remote_username@$remote_hostname "rm --verbose '$repo_path/$bundle_name'"
    git bundle list-heads snapshot.bundle

    if test $status -ne 0
        return $status
    end

    repeatchar -

    # Local
    echo "Extracting bundle on $local_hostname"
    echo

    # git cherry-pick --no-commit refs/tags/snapshot_end \
    git fetch snapshot.bundle refs/tags/snapshot_end:snapshot
    git tag before_bundle_pull
    git checkout snapshot
    git reset --mixed before_bundle_pull

    # Cleanup
    git checkout $current_branch
    git branch --delete snapshot
    git tag -d before_bundle_pull
    git tag -d snapshot_end
    rm $bundle_name
end
