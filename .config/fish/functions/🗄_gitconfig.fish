# ~/.gitconfig is tracked and shared. Sensitive or machine-specific data is
# stored in the alternate global config file.
# > If $XDG_CONFIG_HOME is not set or empty, $HOME/.config/git/config will be used.
function 🗄_gitconfig \
    --description='Sets git user.name and user.email in XDG_CONFIG_HOME' \
    --argument-names email name

    echo "🗄 Git configuration"
    echo

    createdirs ~/.config/git
    set -l global_config ~/.config/git/config
    if not test -d $global_config
        touch $global_config
    end

    # Just print the current config when values are set.
    if git config --file $global_config user.name; and \
            git config --file $global_config user.email
        cat $global_config
        return 0
    end

    # Prompt to add required values

    if test -z "$name"
        echo -n "Git user.name: "
        read name
    end

    if test -z "$email"
        echo -n "Git user.email: "
        read email
    end

    git config --file $global_config user.name "$name"
    git config --file $global_config user.email "$email"

    echo $global_config
    cat $global_config
end
