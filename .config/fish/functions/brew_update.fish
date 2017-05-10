# Short alias for installing gems using Bundler.
function brew_update
    # This can only be run by an admin user
    if not user_is_admin
        exit 1
    end

    brew update
    and brew upgrade

    firewall_allow_nginx
end
