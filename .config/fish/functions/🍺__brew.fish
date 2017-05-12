# Updates Homebrew and installed formulae.
function 🍺__brew
    echo "🍺  Homebrew - https://brew.sh"
    echo

    set -l formulae \
        antigen bash caskroom/cask/brew-cask burl carthage cloc cloudfoundry/tap/cf-cli \
        coreutils curl direnv duti findutils fish git git-lfs gnupg goaccess gradle \
        groovy heroku-toolbelt hub jq thoughtbot/formulae/liftoff maven nginx ninja \
        nodejs packer postgres python rename ruby shellcheck sloccount sourcekitten \
        speedtest_cli kylef/formulae/swiftenv swiftgen swiftlint tailor terminal-notifier \
        thefuck trash tree uncrustify vapor/tap/toolbox wget xctool zsh \

    # Ensure Homebrew is installed.
    if not which -s brew
        echo "Installing Homebrew"
        ruby -e "(curl -fsSL 'https://raw.githubusercontent.com/Homebrew/install/master/install')"
    end

    # Verify the user owns the Homebrew dir.
    set brew_home (brew --prefix)
    if not test (stat -f%u $brew_home) -eq (id -u $USER)
        if status is-login
            echo "You must be the owner of $brew_home to run this command."
        end
        return 1
    end

    # Update
    brew update
    and brew outdated
    and brew upgrade

    # Collect a list of formula which need to be installed
    set -l installed (brew list --full-name)
    set -l not_installed
    for formula in $formulae
        if not contains $formula $installed
            set not_installed $not_installed $formula
        end
    end

    if test -n "$not_installed"
        brew install $not_installed
    end

    firewall_allow_nginx
end
