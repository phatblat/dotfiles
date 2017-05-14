# Updates Fisherman and the plugins it manages. Installs if missing.
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐟__fisherman
    echo "🐟  Fisherman - https://fisherman.github.io"
    echo

    set -l plugins done laughedelic/fish_logo get mock z

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

        ln -Ffs $function_source $function_symlink
        echo "Fisherman installed -> $fisher_dir"
    else
        echo "Updating Fisherman"
        # TODO: Replace with (fisher update)?
        pushd $fisher_dir
        and git pull
        popd
    end

    fisher --version

    for plugin in $plugins
        fisher $plugin
    end

    echo "Installed plugins: "
    fisher ls
end
