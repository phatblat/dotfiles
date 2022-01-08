function 🖥_macos \
    --description='Manage macOS system updates'

    echo "🖥  macOS"

    # Only install Rosetta 2 on M1 if not already installed.
    if begin is_arm; and test ! -f /Library/Apple/usr/share/rosetta/rosetta; end
        echo
        echo "🌍  Rosetta 2"
        sudo softwareupdate --install-rosetta
    end

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

    # set -l log_file (mktemp /tmp/softwareupdate.XXXXXX.log)
    # echo "log_file: $log_file"

    # tail -f $log_file &

    # Download all updates before install
    # Swap stdout and stderr usng 3>&1 1>&2 2>&3 - https://serverfault.com/a/63708/17776
    softwareupdate --download --all --no-scan 3>&1 1>&2 2>&3 | read output

    # Exit when "No updates are available."
    if test -n $output
        echo $output
        return
    end

    # sudo will prompt for password allowing one way to avoid a restart
    sudo softwareupdate --install --all --no-scan --restart
end
