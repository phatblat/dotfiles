# Sets git user.name and user.email
#
# ~/.gitconfig is tracked and shared. Sensitive or machine-specific data is
# stored in the alternate global config file.
# > If $XDG_CONFIG_HOME is not set or empty, $HOME/.config/git/config will be used.
function _gitconfig --argument-names email name
    set -l global_config ~/.config/git/config

    createdirs ~/.config/git

    if test -z $name
        get --prompt "Git user.name: " | read name
    end

    if test -z $email
        get --prompt "Git user.email: " | read email
    end

    git config --file $global_config user.name "$name"
    git config --file $global_config user.email "$email"

    echo $global_config
    cat $global_config
end
