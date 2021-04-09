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
function 🍻_cask \
    --description='Updates Homebrew Casks and installed apps'

    echo "🍻  Homebrew Cask"
    echo

    set -l apps \
        adoptopenjdk/openjdk/adoptopenjdk16 \
        adoptopenjdk8 \
        android-file-transfer \
        android-ndk \
        android-sdk \
        anylist \
        back-in-time \
        banktivity \
        bettertouchtool \
        brave-browser \
        charles \
        cheatsheet \
        cleanmymac \
        dash \
        deckset \
        docker \
        elgato-stream-deck \
        firebase-admin \
        geekbench \
        githubpulse \
        gitkraken \
        google-chrome \
        google-photos-backup-and-sync \
        gpg-suite \
        grammarly \
        hex-fiend \
        ibm-cloud-cli \
        ios-console \
        istat-menus \
        iterm2 \
        jetbrains-toolbox \
        kaleidoscope \
        karabiner-elements \
        keyboard-maestro \
        keycastr \
        kobo \
        latest \
        licecap \
        microblog \
        microsoft-teams \
        macdown \
        ngrok \
        oclint \
        paw \
        periphery \
        rescuetime \
        rocket \
        screens \
        softraid \
        sublime-text \
        sublime-merge \
        teacode \
        textmate \
        the-unarchiver \
        thingsmacsandboxhelper \
        tower \
        transmit \
        visual-studio-code \
        vivaldi \
        vmware-fusion \
        vysor \
        zeplin \
        homebrew/cask-drivers/zsa-wally

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
        homebrew/cask-fonts/font-3270-nerd-font \
        homebrew/cask-fonts/font-aurulent-sans-mono-nerd-font \
        homebrew/cask-fonts/font-awesome-terminal-fonts \
        homebrew/cask-fonts/font-bitstream-vera-sans-mono-nerd-font \
        homebrew/cask-fonts/font-code-new-roman-nerd-font \
        homebrew/cask-fonts/font-dejavu-sans-mono-nerd-font \
        homebrew/cask-fonts/font-droid-sans-mono-nerd-font \
        homebrew/cask-fonts/font-fantasque-sans-mono-nerd-font \
        homebrew/cask-fonts/font-fira-code-nerd-font \
        homebrew/cask-fonts/font-fira-mono-nerd-font \
        homebrew/cask-fonts/font-hack-nerd-font \
        homebrew/cask-fonts/font-heavy-data-nerd-font \
        homebrew/cask-fonts/font-inconsolata-nerd-font \
        homebrew/cask-fonts/font-iosevka-nerd-font \
        homebrew/cask-fonts/font-jetbrains-mono \
        homebrew/cask-fonts/font-lekton-nerd-font \
        homebrew/cask-fonts/font-monofur-nerd-font \
        homebrew/cask-fonts/font-monoid-nerd-font \
        homebrew/cask-fonts/font-mononoki-nerd-font \
        homebrew/cask-fonts/font-mplus-nerd-font \
        homebrew/cask-fonts/font-profont-nerd-font \
        homebrew/cask-fonts/font-roboto-mono-nerd-font \
        homebrew/cask-fonts/font-space-mono-nerd-font \
        homebrew/cask-fonts/font-ubuntu-mono-nerd-font \
        homebrew/cask-fonts/font-consolas-for-powerline \
        homebrew/cask-fonts/font-droid-sans-mono-for-powerline \
        homebrew/cask-fonts/font-dejavu-sans-mono-for-powerline \
        homebrew/cask-fonts/font-fira-mono-for-powerline \
        homebrew/cask-fonts/font-inconsolata-for-powerline \
        homebrew/cask-fonts/font-inconsolata-dz-for-powerline \
        homebrew/cask-fonts/font-inconsolata-g-for-powerline \
        homebrew/cask-fonts/font-liberation-mono-for-powerline \
        homebrew/cask-fonts/font-menlo-for-powerline \
        homebrew/cask-fonts/font-monofur-for-powerline \
        homebrew/cask-fonts/font-meslo-for-powerline \
        homebrew/cask-fonts/font-roboto-mono-for-powerline \
        homebrew/cask-fonts/font-source-code-pro-for-powerline \
        homebrew/cask-fonts/font-ubuntu-mono-derivative-powerline

    set -l all_casks $apps $quicklook_plugins #$fonts

    set -l uninstall \
        1password-cli \
        android-studio \
        anka-flow \
        appium \
        atom \
        battery-guardian \
        bee \
        beoplay-software-update \
        cloudapp \
        cocoapods \
        cocoapods-app \
        dayone-cli \
        dbvisualizer \
        disk-inventory-x \
        docker-toolbox \
        duet \
        fauxpas \
        hipchat \
        hyper \
        java9 \
        mono-mdk \
        opera-gx \
        skype-for-business \
        sublime-text-dev \
        textexpander \
        things \
        timing \
        homebrew/cask-drivers/twelvesouth-bassjump \
        ultimate \
        virtualbox \
        visual-studio \
        xmarks-safari

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

    # Ensure Homebrew is installed.
    if not type -q brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Caskroom dir.
    set -l caskroom_dir (brew_home)/Caskroom
    if test "$USER" != (fileowner $caskroom_dir)
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
    set -l installed (brew list --casks -1 ^/dev/null)
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
            brew update --cask $outdated
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
            brew install --cask $new_cask
        end
    end

    # --------------------------------------------------------------------------
    #
    # Post Install
    #
    # --------------------------------------------------------------------------

    # IBM Cloud
    if contains ibm-cloud-cli $outdated_casks
        if test -f ~/.bashrc.bluemix_uninstall_bak
            echo Cleaning up Bluemix backup file
            diff ~/.bashrc ~/.bashrc.bluemix_uninstall_bak
            rm -f ~/.bashrc.bluemix_uninstall_bak
        end
        if test -f ~/.zshrc.bluemix_uninstall_bak
            echo Cleaning up Bluemix backup file
            diff ~/.zshrc ~/.zshrc.bluemix_uninstall_bak
            rm -f ~/.zshrc.bluemix_uninstall_bak
        end
    end

    echo
    echo 🛀🏻  Cleanup
    # Removes downloads older than 120 days. Add '--prune 30' to shorten this to a month.
    brew cleanup
end
