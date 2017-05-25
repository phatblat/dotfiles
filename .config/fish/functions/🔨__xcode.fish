# Installs and updates Xcode.
# https://developer.apple.com/downloads/
#
# Sequencing
# - After: rubygems (uses xcode-install)
function 🔨__xcode
    echo "🔨  Xcode"
    echo

    if test -z $XCODE_INSTALL_USER; and test -n (user.email)
        set --export --universal XCODE_INSTALL_USER (user.email)
    end

    # Currently selected version
    xcode-select --print-path

    # Update the list of available versions to install
    xcversion update

    # Install the CLI tools, if necessary
    if not test -e /Library/Developer/CommandLineTools/usr/lib/libxcrun.dylib
        # Manual way
        # xcode-select --install
        xcversion install-cli-tools
    end

    echo "Available:"
    xcversion list
    set -l installed (xcversion list)
    set -l newest_version $installed[-1]
    if not string match "*(installed)" $newest_version
        xcversion install $newest_version
    end

    echo
    echo "Installed:"
    xclist
end
