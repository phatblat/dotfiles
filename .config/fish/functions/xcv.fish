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

    if not test -f $version_plist
        error Plist not found: $version_plist
        return 1
    end

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
        # 10.0
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
        case 10A254a
            set beta_version "GM seed "

        # 10.1
        case 10O23ud
            set beta_version "beta 1 "
        case 10O35n
            set beta_version "beta 2 "
        case 10O45e
            set beta_version "beta 3 "

        # 10.2
        case 10P82s
            set beta_version "beta 1 "
        case 10P91b
            set beta_version "beta 2 "
        case 10P99q
            set beta_version "beta 3 "
        case 10P107d
            set beta_version "beta 4 "

        # 11.0
        case 11M336w
            set beta_version "beta 1 "
        case 11M337n
            set beta_version "beta 2 "
        case 11M362v
            set beta_version "beta 3 "
        case 11M374r
            set beta_version "beta 4 "
        case 11M382q
            set beta_version "beta 5 "
        case 11M392q
            set beta_version "beta 6 "
        case 11M392r
            set beta_version "beta 7 "
        case 11A419c
            set beta_version "GM seed 1 "
        case 11A420a
            # This GM became the final GA build
            # set beta_version "GM seed 2 "

        # 11.1
        case 11A1027
            set beta_version "GM seed 1 "
    end

    echo "$marketing_version $beta_version($build_version)"
end
