# Edit .config/omf/bundle to change packages
#
# Sequencing
# - After: brew (fish)
# - Requires Fish Shell
function 🐠_omf \
    --description='Updates oh-my-fish and bundled packages.'

    echo "🐠 oh-my-fish - https://github.com/oh-my-fish/oh-my-fish"
    echo

    set --local remote_install_script \
        https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install
    set --local local_install_script ~/tmp/omf_install

    # https://github.com/oh-my-fish/oh-my-fish#installation
    curl $remote_install_script >$local_install_script

    # Install omf if necessary
    if not functions --query omf
        # Usage: install [options]
        #   Install Oh My Fish

        # Options:
        #   --channel= <channel >Download a specific release channel, either stable or dev (default is "stable").
        #   --check Do a system readiness check without installing.
        #   --config= <path >Put config in a specific path (default is /Users/phatblat/.config/omf).
        #   --help, -h Show this help message.
        #   --noninteractive Disable interactive questions (assume no, use with --yes to assume yes).
        #   --offline[=<path>] Offline install, optionally specifying a tar or directory to use.
        #   --path= <path >Use a specific install path (default is /Users/phatblat/.local/share/omf).
        #   --uninstall Uninstall existing installation instead of installing.
        #   --verbose Enable verbose debugging statements for the installer.
        #   , -y Assume yes for interactive questions.
        fish $local_install_script \
            --config=~/.config/omf \
            --path=~/.local/share/omf \
            --verbose \
            --yes
    end

    if not functions --query omf
        error "omf not installed"
        return 1
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # Update omf and installed plugins
    omf update

    # Install missing packages from .config/omf/bundle
    omf install

    echo "Installed plugins: "
    omf list
    omf doctor
end
