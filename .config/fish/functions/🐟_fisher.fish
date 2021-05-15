# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐟_fisher \
    --description='Updates Fisher and the plugins it manages. Installs if missing.'

    echo "🐟 Fisher - https://github.com/jorgebucaran/fisher"
    echo

    set -l plugins \
        laughedelic/fish_logo \
        get \
        mock \
        nvm \
        z

    set -l repo_url git@github.com:oh-my-fish/oh-my-fish.git
    set -l base_dir ~/dev/shell/fish
    set -l fisher_dir $base_dir/fisher
    set -l function_function $fisher_dir/functions/fisher.fish
    set -l function_symlink ~/.config/fish/functions/fisher.fish

    # Create parent directories
    createdirs $base_dir

    clone_or_pull $fisher_dir $repo_url

    source $function_function \
        && fisher install jorgebucaran/fisher

    fisher --version

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed plugins
    fisher update

    # Restore the symlink to fisher.fish
    # git checkout ~/.config/fish/functions/fisher.fish

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
