# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐟_fisherman \
    --description='Updates Fisherman and the plugins it manages. Installs if missing.'

    echo "🐟 Fisherman - https://fisherman.github.io"
    echo

    set -l plugins \
        laughedelic/fish_logo \
        get \
        mock \
        nvm \
        z

    set -l fisher_dir ~/dev/fish/fisher
    set -l function_source ../../../dev/fish/fisher/fisher.fish
    set -l function_symlink ~/.config/fish/functions/fisher.fish

    # Create parent directories
    createdirs ~/dev/fish

    if not test -e $fisher_dir
        # Extracted from install script
        # https://github.com/fisherman/fisherman#install (git.io/fisher)
        set url "git@github.com:fisherman/fisherman.git"
        git clone $url $fisher_dir

        ln -fsv $function_source $function_symlink
        echo "Fisherman installed -> $fisher_dir"
    else
        echo "Updating Fisherman"
        # TODO: Replace with (fisher update)?
        pushd $fisher_dir
        and git pull
        popd
    end

    fisher --version

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed plugins
    fisher update
    # Restore the symlink to fisher.fish
    git checkout ~/.config/fish/functions/fisher.fish

    # Install any missing plugins
    set -l installed (fisher ls -l)
    echo installed: $installed
    set -l not_installed
    for plugin in $plugins
        set -l plugin_name $plugin

        # Split plugin name off of any in user/repo format
        set -l tokens (string split / $plugin)
        if test (count $tokens) -gt 1
            set plugin_name $tokens[2]
        end

        # Save the full user/plugin name in not_installed
        if not contains $plugin_name $installed
            set not_installed $not_installed $plugin
        end
    end
    echo not_installed: $not_installed
    if test -n "$not_installed"
        for plugin in $not_installed
            echo "Installing $plugin"
            fisher $plugin
        end
    end

    echo "Installed plugins: "
    fisher ls
end
