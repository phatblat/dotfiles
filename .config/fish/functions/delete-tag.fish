#!/usr/bin/env fish
# Deletes a git tag from both the local and remote repos.
function delete-tag --argument-names tag
    if test -z $tag
        echo "Usage: delete-tag <tag>"
        return 1
    end

    # Get the remote for the current branch
    set -l current_branch (git rev-parse --abbrev-ref HEAD)
    set -l current_remote (config branch.$current_branch.remote)

    git tag --delete $tag
    git push $current_remote --delete refs/tags/$tag
end
