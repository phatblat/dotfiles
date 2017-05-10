# Manage TextMate bundles.
function tmbundles
    set -l bundles editorconfig fish gradle tomorrow-theme

    set -l bundle_dev ~/dev/textmate
    set -l bundle_dir ~/Library/Application\ Support/TextMate/Bundles

    if not test -e $bundle_dev
        mkdir -p $bundle_dev
    end
    if not test -e $bundle_dir
        mkdir -p $bundle_dir
    end

    pushd $bundle_dev

    for bundle in $bundles
        if not test -e $bundle.tmbundle
            switch $bundle
                case editorconfig
                    if not test -e editorconfig
                        git clone git@github.com:Mr0grog/editorconfig-textmate.git editorconfig
                    else
                        pushd editorconfig
                        git pull
                        popd
                    end

                    set -l version 0.3.1
                    # curl -L -O -#
                    curl --location --remote-name --progress-bar \
                        https://github.com/Mr0grog/editorconfig-textmate/releases/download/v$version/editorconfig-textmate-$version.tmplugin.zip

                    set newest_file (ls -1t | head -n 1)
                    unzip -o $newest_file
                        and rm -f $newest_file

                    open editorconfig-textmate.tmplugin

                    # Create a dummy bundle file so install isn't repeated.
                    touch $bundle.tmbundle

                case fish
                    git clone git@github.com:l15n/fish-tmbundle.git $bundle.tmbundle

                case gradle
                    git clone git@github.com:alkemist/gradle.tmbundle.git $bundle.tmbundle

                case tomorrow-theme
                    if not test -e tomorrow-theme
                        git clone git@github.com:chriskempson/tomorrow-theme.git
                    else
                        pushd tomorrow-theme
                        git pull
                        popd
                    end
                    set bundle "tomorrow-theme/textmate2/Tomorrow Theme"
            end
        end
        open $bundle.tmbundle
    end

    echo $bundle_dev
    ls
    popd
end
