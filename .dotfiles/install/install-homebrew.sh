#-------------------------------------------------------------------------------
#
# install/install-homebrew.sh
# Repeatable script which installs command-line tools through Homebrew (http://brew.sh)
#
#-------------------------------------------------------------------------------

echo
echo ">>> install-homebrew"
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
    coreutils
    direnv
    duti
    findutils
    git-lfs
    gnupg
    goaccess
    gradle
    groovy
    heroku-toolbelt
    hub
    jq
    thoughtbot/formulae/liftoff
    nginx
    ninja
    nodejs
    packer
    python
    rename
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
    xctool
)

brew install ${formulae[*]}

# Carthage Zsh Completion
# https://github.com/Carthage/Carthage/blob/master/Documentation/BashZshCompletion.md#zsh
ln -Fs /usr/local/Cellar/carthage/0.15/Frameworks/CarthageKit.framework/Versions/A/Scripts/carthage-zsh-completion \
  /usr/local/share/zsh/site-functions/_carthage

