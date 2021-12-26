# Sequencing
# - Requires ruby, but works with system ruby.
function 🍺_brew \
    --description='Updates Homebrew and installed formulae.'

    echo "🍺  Homebrew - https://brew.sh"
    echo

    set -l custom_shells bash fish zsh

    # mac-only formulae
    set -l formulae_mac \
        configen \
        duti \
        fileicon \
        thoughtbot/formulae/liftoff \
        mas \
        screenresolution \
        sourcekitten \
        terminal-notifier \
        trash

    # linux-only formulae
    set -l formulae_linux

    # multi-platform
    set -l formulae \
        artifactory \
        asciinema \
        asdf \
        autoconf \
        automake \
        azure-cli \
        azure/functions/azure-functions-core-tools@3 \
        babel \
        bat \
        burl \
        carthage \
        certbot \
        cloc \
        cmake \
        cmatrix \
        cowsay \
        ctags \
        curl \
        diff-so-fancy \
        direnv \
        docker \
        docker-compose \
        emojify \
        f3 \
        findutils \
        firebase-cli \
        fortune \
        gcovr \
        gh \
        git \
        git-filter-repo \
        git-lfs \
        gnu-sed \
        gnupg \
        go-jira \
        goaccess \
        golang \
        gradle \
        groovy \
        jabba \
        jenv \
        jfrog-cli-go \
        jq \
        jsonlint \
        jsonpp \
        kotlin \
        holgerbrandl/tap/kscript \
        less \
        libarchive \
        libssh2 \
        libtool \
        make \
        markdownlint-cli \
        maven \
        mint \
        mtr \
        nginx \
        node \
        nvm \
        packer \
        pacvim \
        pkg-config \
        python \
        radare2 \
        redis \
        rename \
        rlwrap \
        ruby \
        scrcpy \
        shellcheck \
        sl \
        socat \
        sonar-scanner \
        speedtest-cli \
        svn \
        kylef/formulae/swiftenv \
        swiftformat \
        swiftlint \
        task \
        tasksh \
        tailor \
        thefuck \
        tig \
        tmux \
        travis \
        tree \
        uncrustify \
        utimer \
        yarn \
        $custom_shells

    # Appebd platform-specific formulae
    if is_mac
        set formulae $formulae $formulae_mac
    else if is_linux
        set formulae $formulae $formulae_linux
    end

    # Cleaning macvim with options generates error
    # Error: No available formula with the name "macvim --with-override-system-vim"
    set -l no_clean_formulae macvim ruby

    set -l uninstall \
        android-sdk \
        cask-repair \
        cloudfoundry/tap/cf-cli \
        pivotal/tap/cloudfoundry-cli \
        coreutils \
        docker \
        docker-compose \
        heroku/brew/heroku \
        hub \
        ilmbase \
        imagemagick \
        infer \
        jenkins \
        md5shasum \
        minikube \
        openexr \
        phatblat/services/pbjenkins \
        python@2 \
        sloccount \
        sourcery \
        swiftgen \
        swiftplate \
        vapor \
        vim \
        xctool

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

    # Verify the user owns the Homebrew dir.
    set -l homebrew_dir (brew_home)/Homebrew
    if test "$USER" != (fileowner $homebrew_dir)
        if status is-login
            echo "You must be the owner of "$homebrew_dir" to run this command."
        end
        return 1
    end

    # Ensure Homebrew is installed.
    if not type -q brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # --------------------------------------------------------------------------
    #
    # Update formulae
    #
    # --------------------------------------------------------------------------

    echo 🚰  Updating formulae
    brew update
    set -l installed (brew list --full-name)
    echo
    echo ➡️ (moj_host)  Installed: $installed

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted formulae
    set -l to_uninstall
    for formula in $uninstall
        # Strip off tap prefix (e.g. caskroom/versions/java8)
        set -l tokens (string split / $formula)
        if test (count $tokens) -ge 3
            set formula $tokens[3]
        end

        if contains $formula $installed
            set to_uninstall $to_uninstall $formula
        end
    end
    if test -n "$to_uninstall"
        echo 🗑️  Uninstalling $to_uninstall
        brew uninstall $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed formulae
    set -l outdated_formulae (brew outdated --quiet)
    if test -n "$outdated_formulae"
        echo
        echo 👵🏻 Outdated: $outdated_formulae
        for outdated in $outdated_formulae
            # Strip off tap prefix (e.g. caskroom/versions/java8)
            set -l tokens (string split / $outdated)
            if test (count $tokens) -ge 3
                set outdated $tokens[3]
            end
            brew upgrade --verbose --display-times $outdated
        end
    end

    # Install new formula
    set -l not_installed
    for formula in $formulae
        if not contains $formula $installed
            set not_installed $not_installed $formula
        end
    end
    if test -n "$not_installed"
        for formula in $not_installed
            echo
            echo 🆕  Installing: $formula
            brew install --verbose --display-times $formula
        end
    end

    # --------------------------------------------------------------------------
    #
    # Post Install
    #
    # --------------------------------------------------------------------------

    # Git LFS
    if contains git-lfs $outdated_formulae
        # Update global git config
        git lfs install

        # Update system git config
        git lfs install --system
    end

    # Check whether custom shells are registered
    set -l system_shells_file /etc/shells
    set -l brew_binaries (brew_home)/bin
    set -l system_shells (grep "^$brew_binaries" $system_shells_file)
    for shell in $custom_shells
        set -l shell_path $brew_binaries/$shell
        if not contains $shell_path $system_shells
            if user_is_admin
                echo "Adding $shell_path to $system_shells_file"
                sudo sh -c 'echo '$shell_path' >> '$system_shells_file
            else
                echo "An admin needs to register $shell_path in $system_shells_file before it can be used."
            end
        end
    end

    # Update firewall rules if a new version of nginx was installed
    if contains "nginx" $outdated_formulae
        echo
        firewall_allow_nginx
    end

    # Skip cleanup for some unstable
    for formula in $no_clean_formulae
        if contains $formula $formulae
            set -l index (contains --index $formula $formulae)
            set --erase formulae[$index]
        end
    end

    echo
    echo 🛀🏻  Cleanup
    brew cleanup --prune=30 $formulae

    echo
    echo 👩🏻‍⚕️  Doctor
    brew doctor

    # Slow, takes ~40s on greymatter
    # echo
    # echo ℹ️  Info
    # brew info
end
