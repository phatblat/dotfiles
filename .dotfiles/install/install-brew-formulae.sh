#-------------------------------------------------------------------------------
#
# install/install-brew-formulae.sh
# Repeatable script which installs command-line tools through Homebrew (http://brew.sh)
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-brew-formulae"
echo

#-------------------------------------------------------------------------------

formulae=(
    # Git (PS1 is super slow with Apple's git)
    git

    # Very important
    zsh

    # Homebrew Cask
    caskroom/cask/brew-cask

    antigen
    bash
    burl
    carthage
    cloc
    cloudfoundry/tap/cf-cli
    coreutils
    curl
    direnv
    duti
    findutils
    fish
    git-lfs
    gnupg
    goaccess
    gradle
    groovy
    heroku-toolbelt
    hub
    jq
    thoughtbot/formulae/liftoff
    maven
    nginx
    ninja
    nodejs
    packer
    postgres
    python
    rename
    ruby
    shellcheck
    sloccount
    sourcekitten
    speedtest_cli
    kylef/formulae/swiftenv
    swiftgen
    swiftlint
    tailor
    terminal-notifier
    thefuck
    trash
    tree
    uncrustify
    vapor/tap/toolbox
    wget
    xctool
)

brew install ${formulae[*]}
