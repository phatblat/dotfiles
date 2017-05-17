# Updates Homebrew and installed formulae.
#
# Sequencing
# - Requires ruby, but works with system ruby.
function 🍺__brew
    echo "🍺  Homebrew - https://brew.sh"
    echo

    set -l custom_shells bash fish zsh

    set -l formulae \
        antigen \
        burl \
        carthage \
        cloc \
        cloudfoundry/tap/cf-cli \
        coreutils \
        curl \
        direnv \
        duti \
        findutils \
        git \
        git-lfs \
        gnupg \
        goaccess \
        gradle \
        groovy \
        heroku \
        jq \
        thoughtbot/formulae/liftoff \
        maven \
        nginx \
        ninja \
        node \
        packer \
        postgresql \
        python \
        rename \
        ruby \
        shellcheck \
        sloccount \
        sourcekitten \
        speedtest_cli \
        kylef/formulae/swiftenv \
        swiftgen \
        swiftlint \
        tailor \
        terminal-notifier \
        thefuck \
        trash \
        tree \
        uncrustify \
        vim \
        vapor/tap/toolbox \
        wget \
        xctool \
        $custom_shells

    set -l no_clean_formulae ruby

    set -l uninstall hub pivotal/tap/cloudfoundry-cli

    # Ensure Homebrew is installed.
    if not which -s brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Homebrew dir.
    if test $USER != (fileowner (brew_home))
        if status is-login
            echo "You must be the owner of "(brew_home)" to run this command."
        end
        return 1
    end

    # Update Homebrew
    brew update
    set -l installed (brew list --full-name)

    # Uninstall unwanted formulae
    set -l to_uninstall
    for formula in $uninstall
        if contains $formula $installed
            set to_uninstall $to_uninstall $formula
        end
    end
    if test -n "$to_uninstall"
        brew uninstall $to_uninstall
    end

    # Update installed formulae
    set -l outdated_formulae (brew outdated)
    echo $outdated_formulae | tr ' ' \n
    brew upgrade

    # Install new formula
    set -l not_installed
    for formula in $formulae
        if not contains $formula $installed
            set not_installed $not_installed $formula
        end
    end
    if test -n "$not_installed"
        brew install $not_installed
    end

    # Ruby
    set -l desired_ruby 2.4.1_1
    set -l ruby_versions (brew_versions ruby)
    if not test $desired_ruby = (brew_active_version ruby)
        if contains -- $desired_ruby $ruby_versions
            brew switch ruby $desired_ruby
            brew link --overwrite ruby

            # May need to purge old gems
            # http://stackoverflow.com/questions/9434002/how-to-solve-ruby-installation-is-missing-psych-error#answer-43843417
            # sudo chown -R $USER /usr/local/lib/ruby/gems/
            # and rm -rf /usr/local/lib/ruby/gems/
            # and brew reinstall ruby
        else
            echo "Ruby $desired_ruby is not installed."
        end
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

    # Cleanup
    for formula in $no_clean_formulae
        set --erase formulae[(contains --index $formula $formulae)]
    end
    # Cleanup the remaining formulae
    brew cleanup --prune=30 $formulae

    # Doctor
    brew doctor

    # Info
    brew info
end
