function brew_edit \
    --description='Manages Homebrew formulae' \
    --argument-names token formula_version

    set -l branch $token

    if test -z "$token"
        echo "Usage: brew_edit token [formula_version]"
        return 1
    else if test -n "$formula_version"
        set branch $token"-"$formula_version
    end

    # Special handling for certain formulae
    switch $token
        case mas
            brew untap mas-cli/tap
            # brew uninstall --ignore-dependencies mas
    end

    # /usr/local/Homebrew/Library/Taps/homebrew/homebrew-core/Formula/
    brew_core

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
end
