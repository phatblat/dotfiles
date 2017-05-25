# Manage Homebrew casks.
function cask_edit --argument-names token
    if test -z $token
        echo "Usage: cask_edit token"
        return 1
    end

    pushd (brew --repository)/Library/Taps/caskroom/homebrew-cask
    git checkout master
    git pull
    git checkout -b $token

    if brew cask info $token >/dev/null 2>&1
        # If token exists, edit it
        brew cask edit $token
    else
        # Otherwise, create
        brew cask create $token
    end
end
