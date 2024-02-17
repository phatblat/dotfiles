function version \
    --description='Manage version numbers for an Xcode project.' \
    --argument-names action market_version build_version

    if test -z $action
        set action '*'
    end

    switch $action
        case build
            version_build
        case market
            version_market
        case set
            if test -z $market_version
                echo "Usage: version set 1.1 123456"
                return 1
            end

            agvtool new-marketing-version $market_version >/dev/null

            if test -n $build_version
                agvtool new-version -all $build_version >/dev/null
            end

            version_current
        case bump
            set build_version (version_build)
            agvtool next-version -all >/dev/null

            # Workaround for agvtool dropping leading zeros, assumes only a single zero (e.g. 010001)
            set -l first_number (echo "$build_version" | cut -c1)
            if test $first_number == 0
                set build_version (version_build)
                agvtool new-version -all "0"$build_version >/dev/null
            end

            version_current
        case '*'
            version_current
    end
end
