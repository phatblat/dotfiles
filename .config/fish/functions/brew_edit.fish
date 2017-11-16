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
    pushd (brew_home)
    git checkout master
    git pull
    git checkout -b $branch

    if brew info $token >/dev/null 2>&1
        # If token exists, edit it
        brew edit $token
    else
        # Otherwise, create
        brew create $token
    end

    brew install --build-from-source $token
    brew audit --strict $token
end

