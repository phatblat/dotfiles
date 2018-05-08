# Updates oh-my-fish and the plugins it manages. Installs if missing.
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐠__omf
    echo "🐠  oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo

    set -l plugins \
        brew \
        nvm

    set -l themes none

    set -l omf_dir ~/dev/fish/oh-my-fish

    # Create parent directories
    createdirs ~/dev/fish

    clone_or_pull $omf_dir git@github.com:oh-my-fish/oh-my-fish.git

    # Install omf if necessary
    if not functions --query omf
        pushd $omf_dir
        bin/install --offline
        popd
    end


    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update omf and installed plugins
    omf update

    # Install any missing plugins
    set -l installed_plugins
    for plugin in (omf list --plugin | string split \t)
        # Skip empty strings
        if test -n "$plugin"
            set installed_plugins $installed_plugins $plugin
        end
    end

    echo installed_plugins: $installed_plugins
    set -l not_installed
    for plugin in $plugins
        # set -l plugin_name $plugin

        # Split plugin name off of any in user/repo format
        # set -l tokens (string split / $plugin)
        # if test (count $tokens) -gt 1
        #     set plugin_name $tokens[2]
        # end

        if not contains $plugin $installed_plugins
            set not_installed $not_installed $plugin
        end
    end
    echo not_installed: $not_installed
    if test -n "$not_installed"
        for plugin in $not_installed
            echo "Installing $plugin"
            omf install $plugin
        end
    end

    echo "Installed plugins: "
    omf list
    omf doctor
end
