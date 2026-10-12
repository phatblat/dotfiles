# macos - Manage macOS system updates (converted from 🖥_macos)
export def macos [] {
    print "🖥  macOS"

    # Only install Rosetta 2 on M1 if not already installed
    let arch = (^uname -m | str trim)
    if ($arch == "arm64") and (not ("/Library/Apple/usr/share/rosetta/rosetta" | path exists)) {
        print ""
        print "🌍  Rosetta 2"
        ^sudo softwareupdate --install-rosetta
    }

    print ""
    print "⌛️  Recently installed macOS system updates"
    ^softwareupdate --history

    print ""
    print "🔎  Checking macOS system updates"
    ^softwareupdate --list

    print ""
    print "⬆️  Updating macOS system software"

    # Download all updates before install
    let result = (do { ^softwareupdate --download --all --no-scan } | complete)
    let output = (($result.stdout + $result.stderr) | str trim)

    # Exit when "No updates are available."
    if not ($output | is-empty) {
        print $output
        return
    }

    # sudo will prompt for password allowing one way to avoid a restart
    ^sudo softwareupdate --install --all --no-scan --restart
}
