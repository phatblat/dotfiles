# Manage Homebrew formulae.
function brew_edit --argument-names token version
    set -l branch $token

    if test -z "$token"
        echo "Usage: brew_edit token [version]"
        return 1
    else if test -n "$version"
        set branch $token"-"$version
    end

    # /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/jenkins.rb
    # brew --repository homebrew/core
    pushd (brew_home)/Homebrew/Library/Taps/homebrew/homebrew-core/Formula
    # TODO: Add/update fork

    git checkout master
    git pull origin master
    git checkout -b $branch

    if brew info $token >/dev/null 2>&1
        # If token exists, edit it
        brew edit $token
    else
        # Otherwise, create
        brew create $token
    end

    brew tests
    brew uninstall $token
    brew install --build-from-source $token
    brew test $token
    brew audit --strict $token

    # TODO: Commit
    #git commit -m "$token $version"
    # TODO: Publish branch
    #git push --set-upstream phatblat $branch
    # TODO: Open PR with hub
end

