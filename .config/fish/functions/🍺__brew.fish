# Updates Homebrew and installed formulae.
#
# Sequencing
# - Requires ruby, but works with system ruby.
function 🍺__brew
    echo "🍺  Homebrew - https://brew.sh"
    echo

    set -l formulae \
        antigen bash burl carthage cloc cloudfoundry/tap/cf-cli \
        coreutils curl direnv duti findutils fish git git-lfs gnupg goaccess gradle \
        groovy heroku hub jq thoughtbot/formulae/liftoff maven nginx ninja node packer \
        postgresql python rename ruby shellcheck sloccount sourcekitten speedtest_cli \
        kylef/formulae/swiftenv swiftgen swiftlint tailor terminal-notifier thefuck \
        trash tree uncrustify vapor/tap/toolbox wget xctool zsh

    set -l uninstall hub pivotal/tap/cloudfoundry-cli

    # Ensure Homebrew is installed.
    if not which -s brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Homebrew dir.
    set brew_home (brew --prefix)
    if test $USER != (fileowner $brew_home)
        if status is-login
            echo "You must be the owner of $brew_home to run this command."
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
    brew outdated
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

    # Update firewall rules if a new version of nginx was installed
    if contains "nginx" $outdated_formulae
        echo
        firewall_allow_nginx
    end

    # Cleanup
    brew cleanup

    # Doctor
    brew doctor
end
