# Manage Homebrew casks.
function cask_edit --argument-names token version
    set -l branch $token

    if test -z "$token"
        echo "Usage: cask_edit token [version]"
        return 1
    else if test -n "$version"
        set branch $token"-"$version
    end

    pushd (brew --repository)/Library/Taps/caskroom/homebrew-cask
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
