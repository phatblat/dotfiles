#-------------------------------------------------------------------------------
#
# ios/alias.zsh
# Command-line aliases for iOS development
#
#-------------------------------------------------------------------------------
# Xcode
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias version_build='agvtool what-version -terse'
alias version_market='agvtool what-marketing-version -terse1'

function version_current() {
    local build_version market_version
    build_version=$(version_build)
    market_version=$(version_market)
    echo "$market_version ($build_version)"
}

function version() {
    local agvtool_path build_version first_number
    agvtool_path=$(which agvtool) # "/usr/bin/agvtool"

    case "$1" in
        "build" | "-b")
            version_build
            ;;
        "market" | "-m")
            version_market
            ;;
        "set")
            agvtool new-marketing-version $2 > /dev/null
            if (($+3)); then
                agvtool new-version -all $3 > /dev/null
            fi
            version_current
            ;;
        "next" | "bump")
            build_version=$(version_build)
            agvtool next-version -all > /dev/null

            # Workaround for agvtool dropping leading zeros, assumes only a single zero (e.g. 010001)
            first_number=$(echo $build_version | cut -c1)
            if [[ $first_number == "0" ]]; then
                build_version=$(version_build)
                agvtool new-version -all "0$build_version" > /dev/null
            fi

            version_current
            ;;
        *)
            version_current
            ;;
    esac
}

