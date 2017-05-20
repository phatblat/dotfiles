# Runs bundle-pull.rb ruby script
function bundle-pull
    # bundle exec ~/.dotfiles/git/bundle-pull.rb $argv

    # New logic

    # Ensure current dir is in a clean git repo
    if not git_inside_repo
        echo "This command must be run inside a git repo."
        return 1
    end

    # if git_repo_dirty
    #     echo "The work tree is dirty, aborting."
    #     return 2
    # end

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
    echo remote_hostname $remote_hostname

    set -l username $USER
    set -l repo_path $PWD
    set -l current_branch (current-branch)

    # Create a git bundle file containing the diff of the working copy to HEAD.
    ssh $username@$remote_hostname 'cd '$repo_path'; and git_bundle_create'

    return

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
    git checkout $current_branch
    git branch --delete snapshot
    git tag -d before_bundle_pull
    git tag -d snapshot_end
    rm $bundle_name
end
