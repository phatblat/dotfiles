#-------------------------------------------------------------------------------
#
# ios/alias.zsh
# Command-line aliases for iOS development
#
#-------------------------------------------------------------------------------
# Xcode
alias ox='open *.xcodeproj'
alias ow='open *.xcworkspace'
alias version_enable='ruby ~/.dotfiles/ios/enable-versioning.rb'
alias version_build='agvtool what-version -terse'
alias version_market='agvtool what-marketing-version -terse1'
alias demangle='xcrun swift-demangle'
alias plcat='plutil -convert xml1 -o /dev/stdout'

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

function release() {
    local version dirty branch
    #echo "release function"

    # Ensure current dir is in a clean git repo
    if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
        dirty=$(parse_git_dirty)
        if [[ -n $dirty ]]; then
            echo "Can't release with a dirty work tree"
            return 1
        fi

        # Verify that there is a valid Xcode project in the current dir
        version_build > /dev/null
        if [ $? -ne 0 ]; then
            agvtool what-version
            return 1
        fi

        # Release notes
        echo "Have you checked in your release notes?"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) echo "YES"; break;;
                No ) echo "NO"; return 0;;
            esac
        done

        # Version
        version bump
        build_version=$(version_build)

        # Track and share
        git add --update
        git commit --message "Version $build_version"
        git tag "release/$build_version"
        # TODO: Determine default remote to used so that push commands can be combined
        # branch=$(git symbolic-ref --short HEAD)
        git push
        git push --tags

        # Final status
        version

        # Crashlytics
        # crashlytics_submit=$(find . -name submit 2>/dev/null)
        # if $(crashlytics_submit); then
        #     echo "Upload build to Crashlytics?"
        #     select yn in "Yes" "No"; do
        #         case $yn in
        #             Yes ) echo "YES"; break;;
        #             No ) echo "NO"; return 0;;
        #         esac
        #     done
        #     $crashlytics_submit ...
        # fi
    else
        echo "The release command must be run in a git repo"
    fi
}
