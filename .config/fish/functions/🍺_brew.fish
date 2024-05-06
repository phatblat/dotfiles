# Sequencing
# - Requires ruby, but works with system ruby.
function 🍺_brew \
    --description 'Updates Homebrew and installed formulae.'

    echo "🍺 Homebrew - https://brew.sh"
    echo

    # --------------------------------------------------------------------------
    #
    # Configuration
    #
    # --------------------------------------------------------------------------

    set -l custom_shells bash fish zsh

    # mac-only formulae
    set -l formulae_mac \
        configen \
        duti \
        fileicon \
        mas \
        screenresolution \
        sourcekitten \
        terminal-notifier \
        trash \
        robotsandpencils/made/xcodes

    # linux-only formulae
    set -l formulae_linux

    # multi-platform
    set -l formulae \
        gofireflyio/aiac/aiac \
        aria2 \
        asciinema \
        asdf \
        autoconf \
        automake \
        awscli \
        babel \
        bat \
        boost \
        bottom \
        broot \
        carthage \
        cheat \
        choose \
        clang-format \
        cmatrix \
        ctags \
        curl \
        curlie \
        danger/tap/danger-swift \
        diff-so-fancy \
        direnv \
        duf \
        dust \
        emojify \
        f3 \
        fd \
        findutils \
        firebase-cli \
        fortune \
        fzf \
        gcovr \
        gh \
        git \
        git-filter-repo \
        git-delta \
        git-lfs \
        git-subrepo \
        glances \
        gnu-sed \
        go \
        goaccess \
        gradle \
        groovy \
        gping \
        gtop \
        httpie \
        hyperfine \
        ios-deploy \
        jabba \
        jenv \
        jq \
        jsonlint \
        jsonpp \
        just \
        kotlin \
        holgerbrandl/tap/kscript \
        lastpass-cli \
        less \
        libarchive \
        libssh2 \
        libtool \
        llvm \
        loc \
        lsd \
        macchina \
        make \
        markdownlint-cli \
        maven \
        mcfly \
        mint \
        mise \
        mono-libgdiplus \
        mtr \
        neovim \
        nginx \
        nmap \
        node \
        openjdk \
        openjdk@11 \
        openjdk@17 \
        hashicorp/tap/packer \
        pacvim \
        peripheryapp/periphery/periphery \
        pkg-config \
        prettier \
        procs \
        publish \
        python@3.9 \
        qt \
        radare2 \
        redis \
        rename \
        ripgrep \
        ripgrep-all \
        rlwrap \
        ruby \
        sccache \
        scrcpy \
        sd \
        sevenzip \
        shellcheck \
        shfmt \
        sl \
        socat \
        sonar-scanner \
        speedtest-cli \
        kylef/formulae/swiftenv \
        swiftformat \
        swiftlint \
        swig \
        starship \
        task \
        tasksh \
        tailor \
        the_silver_searcher \
        thefuck \
        tig \
        tldr \
        tmux \
        travis \
        tree \
        typescript \
        uncrustify \
        utimer \
        virtualenv \
        watchman \
        xcbeautify \
        xh \
        yarn \
        zoxide \
        $custom_shells
    # END: formulae

    # Append platform-specific formulae
    if is_mac
        set formulae $formulae $formulae_mac
    else if is_linux
        set formulae $formulae $formulae_linux
    end

    set -l no_clean_formulae ruby

    # FIXME: Can't uninstall dependencies:
    # - coreutils
    # - openexr
    # Error: Refusing to uninstall /usr/local/Cellar/openexr/3.1.3 and /usr/local/Cellar/coreutils/9.0
    # because they are required by aom, asdf, ffmpeg, jpeg-xl, libheif and scrcpy, which are currently installed.
    # You can override this and force removal with:
    # brew uninstall --ignore-dependencies coreutils docker docker-compose openexr

    set -l uninstall \
        android-sdk \
        azure-cli \
        azure/functions/azure-functions-core-tools@3 \
        cask-repair \
        certbot \
        cloudfoundry/tap/cf-cli \
        pivotal/tap/cloudfoundry-cli \
        cmake \
        docker \
        docker-compose \
        dotnet \
        gnupg \
        go-jira \
        heroku/brew/heroku \
        hexyl \
        hub \
        ilmbase \
        imagemagick \
        infer \
        jenkins \
        jfrog-cli-go \
        kubectx \
        kubernetes-cli \
        thoughtbot/formulae/liftoff \
        md5shasum \
        minikube \
        mono \
        neofetch \
        nvm \
        phatblat/services/pbjenkins \
        ping-devops \
        protobuf protobuf-c \
        pyenv \
        python-distlib \
        python-platformdirs \
        python@2 \
        sloccount \
        sourcery \
        subversion \
        swiftgen \
        swiftplate \
        terraform \
        vapor \
        vim \
        xcinfo \
        xcproj \
        xctool \
        yara
    # END: uninstall

    # --------------------------------------------------------------------------
    #
    # Preflight Checks
    #
    # --------------------------------------------------------------------------

    # Determine the appropriate path to Homebrew
    if is_arm
        # /opt/homebrew/
        set homebrew_dir (brew_home)
    else
        # /usr/local/Homebrew
        set homebrew_dir (brew_home)/Homebrew
    end
    echo "homebrew_dir: $homebrew_dir"

    # Verify the user owns the Homebrew dir.
    if test "$USER" != (fileowner $homebrew_dir)
        if status is-login
            echo "You must be the owner of "$homebrew_dir" to run this command."
        end
        return 1
    end

    # Ensure Homebrew is installed.
    if not type --query brew
        echo "📥 Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # --------------------------------------------------------------------------
    #
    # Self-update
    #
    # --------------------------------------------------------------------------

    echo "⬆️ Updating Homebrew"
    brew update

    # --------------------------------------------------------------------------
    #
    # Update formulae
    #
    # --------------------------------------------------------------------------

    echo "🚰  Updating formulae"

    set -l installed (brew list --formulae --full-name)
    echo
    echo ➡️ (moj_host) Installed: $installed

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted formulae
    set -l to_uninstall
    for formula in $uninstall
        if contains $formula $installed
            set to_uninstall $to_uninstall $formula
        end
    end
    if test -n "$to_uninstall"
        echo 🗑️ Uninstalling $to_uninstall
        brew uninstall --formulae $to_uninstall
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update installed formulae
    set -l outdated_formulae (brew outdated --formulae --quiet)
    if test -n "$outdated_formulae"
        echo
        echo "👵🏻 Outdated: $outdated_formulae"
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
            echo 🆕 Installing: $formula
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
    if contains nginx $outdated_formulae
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
    echo 🛀🏻 Cleanup
    brew cleanup --prune=30 $formulae

    echo
    echo 👩🏻‍⚕️ Doctor
    brew doctor

    echo
    echo ℹ️ Info
    brew info
end
