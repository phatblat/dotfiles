function sync \
    --description='Synchronizes a git rep.'

    if git_repo_dirty
        echo "📥 Stashing changes"
        stsave
    end

    set -l sync_branch master
    if test $sync_branch != (current_branch)
        git checkout $sync_branch
    end

    pull

    set -l remote_name (remote_for_current_branch)
    prune $remote_name

    bra

    echo "prompt to delete any tracking branches that have lost their remotes, gone in bra output"
end
