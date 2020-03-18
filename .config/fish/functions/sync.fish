function sync \
    --description='Synchronizes a git rep.'

    if git_repo_dirty
        echo "📥 Stashing changes"
        stsave
    end

    c master
    pull

    set -l remote_name (remote_for_current_branch)
    prune $remote_name

    bra

    echo "prompt to delete any tracking branches that ahve lost their remotes, gone in bra output"
end
