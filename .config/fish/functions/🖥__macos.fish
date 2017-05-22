# Manage macOS system updates.
function 🖥__macos
    echo "🖥  macOS"
    echo

    echo "Updating Mac App Store apps"

    echo using mas (mas version)
    mas account
    mas outdated
    mas upgrade

    echo
    echo "Updating system software"

    softwareupdate --list

    # Example output:
    # Software Update Tool
    #
    # Finding available software
    # Software Update found the following new or updated software:
    #    * MacBookAirEFIUpdate2.4-2.4
    #         MacBook Air EFI Firmware Update (2.4), 3817K [recommended] [restart]
    #    * ProAppsQTCodecs-1.0
    #         ProApps QuickTime codecs (1.0), 968K [recommended]
    #    * JavaForOSX-1.0
    #         Java for OS X 2012-005 (1.0), 65288K [recommended]
    #-----
    # Software Update Tool
    #
    # Finding available software
    # No new software available.

    # Combine all switches?
    # softwareupdate --list --download --all
    # TODO: Need sudo to install
    # softwareupdate --install --all
end
