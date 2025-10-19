#!/usr/bin/env fish
function wip \
    --description='Commits WIP work'

    if git_repo_clean
        error 'There is nothing to commit. The working copy is clean.'
        return 1
    end

    git add --all
    git commit -am "🚧 WIP"
end
