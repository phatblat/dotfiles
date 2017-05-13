# Updates Homebrew Casks and installed apps (casks).
function 🍻__cask
    echo "🍻  Homebrew Cask - https://caskroom.github.io"
    echo

    set -l casks \
        atom \
        charles \
        cloudapp \
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
        kaleidoscope \
        macdown \
        oclint \
        omnigraffle \
        omnipresence \
        quickradar \
        simpholders \
        sublime-text \
        textexpander \
        things \
        tower \
        virtualbox \
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
        webpquicklook \

    # echo $casks | tr ' ' \n
    # return

    # Ensure Homebrew is installed.
    if not which -s brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Homebrew dir.
    # TODO: Should this be /usr/local/Caskroom?
    set brew_home (brew --prefix)
    if not test (stat -f%u $brew_home) -eq (id -u $USER)
        if status is-login
            echo "You must be the owner of $brew_home to run this command."
        end
        return 1
    end

    # Update
    brew update
    and set -l outdated_casks (brew cask outdated)
    and brew cask outdated
    # and brew upgrade

    # Collect a list of casks which need to be installed
    set -l installed (brew cask list)
    set -l not_installed
    for cask in $casks
        if not contains $cask $installed
            set not_installed $not_installed $cask
        end
    end

    if test -n "$not_installed"
        brew cask install $not_installed
    end

    # Update already installed casks
    if test -n "$outdated_casks"
        brew cask reinstall --force $outdated_casks
    end
end
