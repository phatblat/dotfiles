function brew_test \
    --description 'Installs and tests a Homebrew formula' \
    --argument-names token formula_version

    if test -z "$token"
        echo "Usage: brew_test token [formula_version]"
        return 1
    end

    # Special handling for certain formulae
    switch $token
        case mas
            brew tap --list-pinned | grep mas-cli/tap
            and brew tap-unpin mas-cli/tap
            and trash ~/Library/Caches/org.carthage.CarthageKit
    end

    if brew ls --versions $token >/dev/null
        brew uninstall $token
    end

    brew install --build-from-source $token
    and brew test $token
    and brew audit --strict $token
end
