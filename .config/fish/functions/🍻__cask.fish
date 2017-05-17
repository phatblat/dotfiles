# Updates Homebrew Casks and installed apps (casks).
#
# stderr often outputs several of the following messages, which seem to be
# coming from outdated casks.
#
#   Warning: Calling "cask :v1 => 'token'" is deprecated!
#   Use "cask 'token'" instead.
#   /usr/local/Homebrew/Library/Homebrew/cask/lib/hbc/cask_loader.rb:9:in `load'
#
# Sequencing
# - Requires ruby, but works with system ruby.
# - Seems logical to run after brew, but not actually required.
function 🍻__cask
    echo "🍻  Homebrew Cask - https://caskroom.github.io"
    echo

    set -l casks \
        atom \
        back-in-time \
        charles \
        cloudapp \
        dbvisualizer \
        dayone-cli \
        fauxpas \
        geekbench \
        github-desktop \
        google-chrome \
        gpgtools \
        hipchat \
        intellij-idea \
        ios-console \
        istat-menus \
        iterm2 \
        java \
        kaleidoscope \
        macdown \
        oclint \
        omnigraffle \
        omnipresence \
        quickradar \
        simpholders \
        sublime-text \
        textexpander \
        # things \
        tower \
        transmit \
        virtualbox \
        vmware-fusion \
        # QuickLook plugins
        betterzipql \
        provisioning \
        qlcolorcode \
        qlimagesize \
        qlmarkdown \
        qlprettypatch \
        # preview files without an extension as text
        qlstephen \
        quicklook-csv \
        quicklook-json \
        textmate \
        webpquicklook

    set -l uninstall battery-guardian cocoapods cocoapods-app things

    # Ensure Homebrew is installed.
    if not which -s brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Homebrew dir.
    # TODO: Should this be (brew_home)/Caskroom?
    if test $USER != (fileowner (brew_home))
        if status is-login
            echo "You must be the owner of "(brew_home)" to run this command."
        end
        return 1
    end

    # Update
    brew update
    set -l installed (brew cask list -1 ^/dev/null)

    # Uninstall unwanted formulae
    set -l to_uninstall
    for cask in $uninstall
        if contains $cask $installed
            set to_uninstall $to_uninstall $cask
        end
    end
    if test -n "$to_uninstall"
        brew cask uninstall $to_uninstall
    end

    # Update installed casks
    set -l outdated_output (brew cask outdated ^/dev/null)
    # Example: charles (4.1.1) != 4.1.2
    echo $outdated_output\n
    # Cut everything but the first column
    set -l outdated_casks (echo $outdated_output\n | cut -f 1 -d ' ' -)
    if test -n "$outdated_casks"
        brew cask reinstall --force $outdated_casks
    end

    # Install new casks
    set -l not_installed
    for cask in $casks
        if not contains $cask $installed
            set not_installed $not_installed $cask
        end
    end
    if test -n "$not_installed"
        brew cask install --force $not_installed
    end

    # Cleanup
    brew cask cleanup --outdated
end
