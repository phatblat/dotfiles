# Manage TextMate bundles.
function tmbundles
    set -l bundles editorconfig fish gradle
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
                    git clone git@github.com:Mr0grog/editorconfig-textmate.git $bundle.tmbundle
                case fish
                    git clone git@github.com:l15n/fish-tmbundle.git $bundle.tmbundle
                case gradle
                    git clone git@github.com:alkemist/gradle.tmbundle.git $bundle.tmbundle
            end
        end
        open $bundle.tmbundle
    end

    echo $bundle_dev
    ls
    popd
end
