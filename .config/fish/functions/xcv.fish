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
    if test $active_version = /Library/Developer/CommandLineTools
        echo -n "$active_version - "

        # CLI tools are the active version of Xcode
        pkgutil --pkg-info=com.apple.pkg.DevSDK \
        | grep version \
        | awk '{print $2}'

        return
    end

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
            # This GM became the final GA build
            # set beta_version "GM seed 1 "

        # 11.2
        case 11B41
            set beta_version "beta 1 "
        case 11B44
            set beta_version "beta 2 "

        # 11.2.1
        case 11B53
            set beta_version "GM seed "

        # 11.3
        case 11C24b
            set beta_version "beta 1 "

        # 11.4
        case 11N111s
            set beta_version "beta 1 "
        case 11N123k
            set beta_version "beta 2 "
        # This build was released as the final version
        # case 11N132i
        #     set beta_version "beta 3 "

        # 12.0
        case 12A6159
            set beta_version "beta 1 "
        case 12A6163b
            set beta_version "beta 2 "
        case 12A8169g
            set beta_version "beta 3 "
        case 12A8179i
            set beta_version "beta 4 "
        case 12A8189h
            set beta_version "beta 5 "
        case 12A8189n
            set beta_version "beta 6 "

        # 12.1.1
        case 12A7605b
            set beta_version "RC "

        # 12.2
        case 12B5044c
            set beta_version "RC "

        # 13.0
        case 13A5154h
            set beta_version "beta 1 "
        case 13A5155e
            set beta_version "beta 2 "
        case 13A5192j
            set beta_version "beta 3 "
        case 13A5201i
            set beta_version "beta 4 "
        case 13A5212g
            set beta_version "beta 5 "

        # 13.3
        case 13E5086k
            set beta_version "beta 1 "
        case 13E5095k
            set beta_version "beta 2 "
        case 13E5104i
            set beta_version "beta 3 "

        # 14.0
        case 14A5228q
            set beta_version "beta 1 "
        case 14A5229c
            set beta_version "beta 2 "
        case 14A5270f
            set beta_version "beta 3 "
        case 14A5284g
            set beta_version "beta 4 "
        case 14A5294e
            set beta_version "beta 5 "
        case 14A5294g
            set beta_version "beta 6 "
    end

    echo "$marketing_version $beta_version($build_version)"
end
