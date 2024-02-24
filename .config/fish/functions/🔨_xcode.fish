# https://developer.apple.com/downloads/
#
# Sequencing
# - After: rubygems (uses xcode-install)
function 🔨_xcode \
    --description 'Installs and updates Xcode.'

    echo "🔨 Xcode"
    echo

    if test -z $XCODE_INSTALL_USER; and test -n (user.email)
        set --export XCODE_INSTALL_USER (user.email)
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
        set -l options --no-show-release-notes

        # Don't activate beta versions automatically
        if string match beta $newest_version
            set options options --no-switch
        end

        xcversion install $newest_version $options

        # Clean out old simulators
        xcrun simctl delete unavailable
    end

    echo
    echo "Installed:"
    xclist

    echo
    echo Themes
    set -l xcode_themes_dir ~/Library/Developer/Xcode/UserData/FontAndColorThemes
    set -l xcode_dev_dir ~/dev/xcode
    set -l repo_dir $xcode_dev_dir/xcode-themes
    createdirs $xcode_themes_dir $xcode_dev_dir
    clone_or_pull $repo_dir git@github.com:hdoria/xcode-themes.git
    pushd $repo_dir
    for theme in *.dvtcolortheme
        if not test -e $xcode_themes_dir/$theme
            # Only copy new themes
            cp -v $theme $xcode_themes_dir
        end
    end
    popd
end
