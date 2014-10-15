#-------------------------------------------------------------------------------
#
# ios/alias.zsh
# Command-line aliases for iOS development
#
#-------------------------------------------------------------------------------
# Xcode
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'

# agvtool
function version() {
    agvtool_path=$(which agvtool) # "/usr/bin/agvtool"

    case "$1" in
        "build" | "-b")
            agvtool what-version -terse
            ;;
        "market" | "-m")
            agvtool what-marketing-version -terse1
            ;;
        "set")
            agvtool new-marketing-version $2 > /dev/null
            if (($+3)); then
                agvtool new-version -all $3 > /dev/null
            fi
            version_current
            ;;
        "next" | "bump")
            agvtool next-version -all > /dev/null
            version_current
            ;;
        *)
            version_current
            ;;
    esac
}

function version_current() {
    build_version=$(agvtool what-version -terse)
    market_version=$(agvtool what-marketing-version -terse1)
    echo "$market_version ($build_version)"
}
