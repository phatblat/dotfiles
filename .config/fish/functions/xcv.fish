function xcv \
        --description='Displays the version of the currently selected Xcode.' \
        --argument-names short_flag
    # xcodebuild -version takes 250ms
    # Example output:
    #   Xcode 10.0
    #   Build version 10L201y
    # set -l marketing_version (echo $output | awk '{print $2}')
    # set -l build_version (echo $output | awk '{print $5}')

    set -l active_version (xcode-select -p)
    set -l version_plist (string replace Developer '' $active_version)version.plist

    # Parse for marketing version
    set -l marketing_version (\
        plutil -p $version_plist \
        | grep -e CFBundleShortVersionString \
        | sed 's/[^0-9\.]*//g' \
    )

    # Print only the marketing version
    if test -s = $short_flag
        echo $marketing_version
        return
    end

    # Parse for build version
    set -l build_version (\
        plutil -p $version_plist \
        | grep -e ProductBuildVersion \
        | awk '{print $3}' \
        | sed 's/"//g' \
    )

    # Check if this is a beta build
    set -l beta_version
    switch $build_version
        #    10.0
        case 10L176w
            set beta_version "beta 1 "
        case 10L177m
            set beta_version "beta 2 "
        case 10L201y
            set beta_version "beta 3 "
        case 10L213o
            set beta_version "beta 4 "
        case 10L221o
            set beta_version "beta 5 "
        case 10L232m
            set beta_version "beta 6 "
    end

    echo "$marketing_version $beta_version($build_version)"
end
