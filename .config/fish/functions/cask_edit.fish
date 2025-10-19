#!/usr/bin/env fish
# Manage Homebrew casks.
function cask_edit --argument-names token cask_version
    set -l branch $token

    if test -z "$token"
        echo "Usage: cask_edit token [cask_version]"
        return 1
    else if test -n "$cask_version"
        set branch $token"-"$cask_version
    end

    cask_dir
    git checkout master
    git pull
    git checkout -b $branch

    if brew cask info $token >/dev/null 2>&1
        # If token exists, edit it
        brew cask edit $token
    else
        # Otherwise, create
        brew cask create $token
    end
end
