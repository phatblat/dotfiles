# Installs and updates system and shell dependencies.
function _install
    repeatchar -

    # Only prompt for user info when not already set
    if test -z (git config user.email)
        _gitconfig
    else
        echo "Git configuration"
        cat ~/.config/git/config
    end

    repeatchar -
    ♻️_fisherman
    repeatchar -
    ♻️_tmbundles
    repeatchar -
end
