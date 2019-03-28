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
    echo "🍻  Homebrew Cask"
    echo

    set -l apps \
        1password-cli \
        android-ndk \
        android-sdk \
        anka-flow \
        anylist \
        appium \
        atom \
        back-in-time \
        banktivity \
        bee \
        beoplay-software-update \
        bettertouchtool \
        brave-browser \
        cardhop \
        charles \
        cheatsheet \
        cleanmymac \
        cloudapp \
        dbvisualizer \
        dash \
        dayone-cli \
        deckset \
        docker-toolbox \
        duet \
        fauxpas \
        firebase-admin \
        geekbench \
        githubpulse \
        gitkraken \
        google-chrome \
        gpg-suite \
        hex-fiend \
        hipchat \
        hyper \
        ibm-cloud-cli \
        ios-console \
        istat-menus \
        iterm2 \
        java \
        caskroom/versions/java8 \
        jetbrains-toolbox \
        jira-client \
        kaleidoscope \
        keyboard-maestro \
        keycastr \
        kobo \
        licecap \
        lunchy \
        microblog \
        microsoft-teams \
        minikube \
        macdown \
        ngrok \
        oclint \
        omnigraffle \
        omnipresence \
        paste \
        paw \
        peripheryapp/periphery/periphery \
        realm-studio \
        rescuetime \
        rocket \
        screens \
        skype-for-business \
        softraid \
        sublime-text \
        sublime-merge \
        teacode \
        textmate \
        the-unarchiver \
        thingsmacsandboxhelper \
        tower \
        transmit \
        ultimate \
        virtualbox \
        visual-studio-code \
        vmware-fusion \
        zeplin

    set -l quicklook_plugins \
        provisionql \
        qlcolorcode \
        qlimagesize \
        qlmarkdown \
        qlprettypatch \
        # preview files without an extension as text
        qlstephen \
        quicklook-csv \
        quicklook-json \
        webpquicklook

    # TEMP: Cask doesn't check whether fonts are installed. To speed up
    # the upstall process, these are excluded for now.
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
        caskroom/fonts/font-ubuntumono-nerd-font \
        caskroom/fonts/font-anonymice-powerline \
        caskroom/fonts/font-source-code-pro-for-powerline \
        caskroom/fonts/font-monofur-for-powerline \
        caskroom/fonts/font-inconsolata-dz-for-powerline \
        caskroom/fonts/font-inconsolata-for-powerline \
        caskroom/fonts/font-liberation-mono-for-powerline \
        caskroom/fonts/font-menlo-for-powerline \
        caskroom/fonts/font-inconsolata-g-for-powerline \
        caskroom/fonts/font-consolas-for-powerline \
        caskroom/fonts/font-fira-mono-for-powerline \
        caskroom/fonts/font-meslo-for-powerline \
        caskroom/fonts/font-dejavu-sans-mono-for-powerline \
        caskroom/fonts/font-roboto-mono-for-powerline \
        caskroom/fonts/font-droid-sans-mono-for-powerline \
        caskroom/fonts/font-ubuntu-mono-derivative-powerline

    # TODO: Re-enable $fonts on rundmg
    set -l all_casks $apps $quicklook_plugins

    set -l uninstall \
        android-studio \
        battery-guardian \
        cocoapods \
        cocoapods-app \
        disk-inventory-x \
        java9 \
        karabiner-elements \
        mono-mdk \
        sublime-text-dev \
        textexpander \
        things \
        timing \
        homebrew/cask-drivers/twelvesouth-bassjump \
        visual-studio \
        xmarks-safari

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

    # Verify the user owns the Caskroom dir.
    set -l caskroom_dir (brew_home)/Caskroom
    if test $USER != (fileowner $caskroom_dir)
        if status is-login
            echo "You must be the owner of "$caskroom_dir" to run this command."
        end
        return 1
    end

    # if test '10.13' = (osversion)
    #     echo "Skipping Cask on highOS"
    #     return 1
    # end

    # --------------------------------------------------------------------------
    #
    # Update formulae
    #
    # --------------------------------------------------------------------------

    echo 🚰  Updating formulae
    brew update
    set -l installed (brew cask list -1 ^/dev/null)
    echo
    echo ➡️ (moj_host)  Installed: $installed

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted formulae
    set -l to_uninstall
    for cask in $uninstall
        # Strip off tap prefix (e.g. caskroom/versions/java8)
        set -l tokens (string split / $cask)
        if test (count $tokens) -ge 3
            set cask $tokens[3]
        end

        if contains $cask $installed
            set to_uninstall $to_uninstall $cask
        end
    end
    if test -n "$to_uninstall"
        echo
        echo 🗑   Uninstalling $to_uninstall
        brew cask uninstall --force $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed casks
    set -l outdated_casks (brew cask outdated ^/dev/null)
    # Example: charles (4.1.1) != 4.1.2
    # Cut everything but the first column
    # set -l outdated_casks (echo $outdated_casks\n | cut -f 1 -d ' ' -)
    if test -n "$outdated_casks"
        echo
        echo 👵🏻 Outdated: $outdated_casks
        for outdated in $outdated_casks
            brew cask reinstall --force $outdated
        end
    end

    # Install new casks
    set -l not_installed
    for full_cask in $all_casks
        # Strip off tap prefix (e.g. caskroom/versions/java8)
        set -l cask $full_cask
        set -l tokens (string split / $cask)
        if test (count $tokens) -ge 3
            set cask $tokens[3]
        end

        if not contains $cask $installed
            # Use the full cask name prefixed with tap info for install
            set not_installed $not_installed $full_cask
        end
    end
    if test -n "$not_installed"
        echo
        echo 🆕  Installing: $not_installed
        for new_cask in $not_installed
            brew cask install --force $new_cask
        end
    end

    # --------------------------------------------------------------------------
    #
    # Post Install
    #
    # --------------------------------------------------------------------------

    # IBM Cloud
    if contains ibm-cloud-cli $outdated_casks
        if test -f ~/.zshrc.bluemix_uninstall_bak
            echo Cleaning up Bluemix backup file
            diff ~/.zshrc ~/.zshrc.bluemix_uninstall_bak
            rm -f ~/.zshrc.bluemix_uninstall_bak
        end
    end

    echo
    echo 🛀🏻  Cleanup
    brew cleanup -prune=30
end
