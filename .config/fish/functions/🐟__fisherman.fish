# Updates Fisherman and the plugins it manages. Installs if missing.
function 🐟__fisherman
    echo "🐟 Fisherman - https://fisherman.github.io"

    set -l plugins done laughedelic/fish_logo get mock z

    set -l fisherDir ~/dev/fish/fisher
    set -l functionFile ~/.config/fish/functions/fisher.fish

    # Create parent directories
    createdirs ~/dev/fish

    if not test -e $fisherDir
        # Extracted from install script
        # https://github.com/fisherman/fisherman#install (git.io/fisher)
        set url "git@github.com:fisherman/fisherman.git"
        git clone $url $fisherDir

        ln -Ffs $fisherDir/fisher.fish $functionFile
        echo "Fisherman installed -> $fisherDir"
    else
        echo "Updating Fisherman"
        # TODO: Replace with (fisher update)?
        pushd $fisherDir
        and git pull
        and popd
    end

    fisher --version

    for plugin in $plugins
        fisher $plugin
    end

    echo "Installed plugins: "
    fisher ls
end
