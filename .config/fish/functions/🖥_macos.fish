function 🖥_macos \
    --description='Manage macOS system updates'

    echo "🖥  macOS"
    echo

    echo "🌍  Rosetta 2"
    sudo softwareupdate --install-rosetta

    echo
    echo "⌛️  Recently installed macOS system updates"
    softwareupdate --history

    echo
    echo "🔎  Checking macOS system updates"

    softwareupdate --list

    # TODO: Detect when "No new software available." is printed and exit before update logic, exit

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

    echo
    echo "⬆️  Updating macOS system software"

    # Download all updates before install
    softwareupdate --download --all --no-scan

    # sudo will prompt for password allowing one way to avoid a restart
    sudo softwareupdate --install --all --no-scan --restart
end
