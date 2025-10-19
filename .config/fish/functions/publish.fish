#!/usr/bin/env fish
# Publishes the current branch to the named remote.
function publish --argument-names remote
    if test -z $remote
        echo "Usage: publish <remote>"
        return 1
    end

    set -l branch (git rev-parse --abbrev-ref HEAD)
    git push -u $remote $branch
end
