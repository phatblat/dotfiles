# Manage TextMate bundles.
function tmbundles
    set -l bundle_dir ~/Library/Application\ Support/TextMate/Bundles
    set -l bundles fish gradle

    pushd

    for bundle in $bundles
        if not test -e $bundle.tmbundle
            switch $bundle
                case fish
                    git clone git@github.com:l15n/fish-tmbundle.git fish.tmbundle
                case gradle
                    git clone git@github.com:alkemist/gradle.tmbundle.git
            end
        end
        open $bundle.tmbundle
    end

    echo $bundle_dir
    ls -l
    popd
end
