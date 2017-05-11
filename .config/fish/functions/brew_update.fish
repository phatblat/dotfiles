# Short alias for installing gems using Bundler.
function brew_update
    # Verify the user owns the Homebrew dir.
    set brew_home (brew --prefix)
    if not test (stat -f%u $brew_home) -eq (id -u $USER)
        if status is-login
            echo "You must be the owner of $brew_home to run this command."
        end
        return 1
    end

    brew update
    and brew upgrade

    firewall_allow_nginx
end
