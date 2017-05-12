# Updates Fisherman and the plugins it manages. Installs if missing.
function ♻️_fisherman
    # Parent directories
    set -l dirs ~/dev/fish

    for dir in $dirs
        if not test -e $dir
            mkdir -p $dir
        end
    end

    # Fisherman - https://github.com/fisherman/fisherman#install
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
        echo "Updating Fisherman ♻️"
        # TODO: Replace with (fisher update)?
        pushd $fisherDir
        and git pull
        and popd
    end

    fisher --version

    set -l fisherman_plugins done laughedelic/fish_logo get mock z
    for plugin in $fisherman_plugins
        fisher $plugin
    end

    echo "Installed plugins: "
    fisher ls
end
