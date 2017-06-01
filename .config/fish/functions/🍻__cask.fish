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

    set -l apps \
        atom \
        back-in-time \
        charles \
        cheatsheet \
        cleanmymac \
        cloudapp \
        dbvisualizer \
        dash \
        dayone-cli \
        fauxpas \
        geekbench \
        gemini \
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
        paw \
        quickradar \
        simpholders \
        softraid \
        sublime-text \
        textmate \
        thingsmacsandboxhelper \
        tower \
        transmit \
        virtualbox \
        vmware-fusion

    set -l quicklook_plugins \
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
        webpquicklook

    set -l fonts \
        caskroom/fonts/font-3270-nerd-font \
        caskroom/fonts/font-anonymouspro-nerd-font \
        caskroom/fonts/font-aurulentsansmono-nerd-font \
        caskroom/fonts/font-awesome-terminal-fonts \
        caskroom/fonts/font-bitstreamverasansmono-nerd-font \
        caskroom/fonts/font-codenewroman-nerd-font \
        caskroom/fonts/font-dejavu-sans \
        caskroom/fonts/font-dejavu-sans-mono-for-powerline \
        caskroom/fonts/font-dejavusansmono-nerd-font \
        caskroom/fonts/font-droidsansmono-nerd-font \
        caskroom/fonts/font-fantasquesansmono-nerd-font \
        caskroom/fonts/font-firacode-nerd-font \
        caskroom/fonts/font-firamono-nerd-font \
        caskroom/fonts/font-gohu-nerd-font \
        caskroom/fonts/font-hack-nerd-font \
        caskroom/fonts/font-hasklig-nerd-font \
        caskroom/fonts/font-heavydata-nerd-font \
        caskroom/fonts/font-hermit-nerd-font \
        caskroom/fonts/font-inconsolata-nerd-font \
        caskroom/fonts/font-iosevka-nerd-font \
        caskroom/fonts/font-lekton-nerd-font \
        caskroom/fonts/font-liberationmono-nerd-font \
        caskroom/fonts/font-meslo-nerd-font \
        caskroom/fonts/font-monofur-nerd-font \
        caskroom/fonts/font-monoid-nerd-font \
        caskroom/fonts/font-mononoki-nerd-font \
        caskroom/fonts/font-mplus-nerd-font \
        caskroom/fonts/font-profont-nerd-font \
        caskroom/fonts/font-proggyclean-nerd-font \
        caskroom/fonts/font-robotomono-nerd-font \
        caskroom/fonts/font-sharetechmono-nerd-font \
        caskroom/fonts/font-sourcecodepro-nerd-font \
        caskroom/fonts/font-spacemono-nerd-font \
        caskroom/fonts/font-terminus-nerd-font \
        caskroom/fonts/font-ubuntumono-nerd-font

    set -l casks $apps $quicklook_plugins $fonts
    set -l uninstall battery-guardian cocoapods cocoapods-app textexpander things

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

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

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted formulae
    set -l to_uninstall
    for cask in $uninstall
        if contains $cask $installed
            set to_uninstall $to_uninstall $cask
        end
    end
    if test -n "$to_uninstall"
        brew cask uninstall --force $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

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

    # --------------------------------------------------------------------------
    #
    # Post Install
    #
    # --------------------------------------------------------------------------

    # Cleanup
    brew cask cleanup --outdated
end
